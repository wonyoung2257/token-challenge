import Foundation

actor JSONLParser {
    private var fileCache: [String: FileCacheEntry] = [:]
    private let decoder = JSONDecoder()
    private let claudeProjectsPath: String

    // Reuse expensive formatter instances
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let isoFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // Directory scan cache
    private var cachedFileList: [String] = []
    private var lastDirectoryScan: Date = .distantPast
    private let directoryScanInterval: TimeInterval = 120 // re-scan every 2 minutes

    init() {
        self.claudeProjectsPath = (NSHomeDirectory() as NSString)
            .appendingPathComponent(".claude/projects")
    }

    func parseAllRecords() -> [TokenRecord] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: claudeProjectsPath) else { return [] }

        let jsonlFiles = findJSONLFiles(in: claudeProjectsPath)
        var allRecords: [TokenRecord] = []

        for filePath in jsonlFiles {
            let records = parseFile(at: filePath)
            allRecords.append(contentsOf: records)
        }

        return allRecords
    }

    private func findJSONLFiles(in directory: String) -> [String] {
        let now = Date()
        if now.timeIntervalSince(lastDirectoryScan) < directoryScanInterval,
           !cachedFileList.isEmpty {
            // Between full scans, just check if any new files appeared via quick attribute check
            return cachedFileList
        }

        let fm = FileManager.default
        var results: [String] = []

        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return cachedFileList }

        while let url = enumerator.nextObject() as? URL {
            if url.pathExtension == "jsonl" {
                results.append(url.path)
            }
        }

        cachedFileList = results
        lastDirectoryScan = now
        return results
    }

    private func parseFile(at path: String) -> [TokenRecord] {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date,
              let fileSize = attrs[.size] as? UInt64
        else { return [] }

        // Cache hit — file unchanged
        if let cached = fileCache[path],
           cached.modificationDate == modDate,
           cached.fileSize == fileSize {
            return cached.records
        }

        // Incremental parse: if file grew (same mod path, bigger size), only read new bytes
        let existingRecords: [TokenRecord]
        let readOffset: UInt64

        if let cached = fileCache[path], fileSize > cached.fileSize {
            existingRecords = cached.records
            readOffset = cached.fileSize
        } else {
            existingRecords = []
            readOffset = 0
        }

        guard let handle = FileHandle(forReadingAtPath: path) else {
            return existingRecords
        }
        defer { handle.closeFile() }

        handle.seek(toFileOffset: readOffset)
        let newData = handle.readDataToEndOfFile()

        guard !newData.isEmpty,
              let content = String(data: newData, encoding: .utf8)
        else {
            return existingRecords
        }

        var newRecords: [TokenRecord] = []

        content.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8)
            else { return }

            guard let entry = try? self.decoder.decode(JSONLEntry.self, from: lineData),
                  entry.type == "assistant",
                  let message = entry.message,
                  let usage = message.usage,
                  let timestampStr = entry.timestamp,
                  let date = self.isoFormatter.date(from: timestampStr) ?? self.isoFallback.date(from: timestampStr)
            else { return }

            let total = usage.total
            guard total > 0 else { return }

            let record = TokenRecord(
                timestamp: date,
                model: message.model ?? "unknown",
                inputTokens: usage.input_tokens ?? 0,
                outputTokens: usage.output_tokens ?? 0,
                cacheCreationTokens: usage.cache_creation_input_tokens ?? 0,
                cacheReadTokens: usage.cache_read_input_tokens ?? 0
            )
            newRecords.append(record)
        }

        let allRecords = existingRecords + newRecords

        fileCache[path] = FileCacheEntry(
            modificationDate: modDate,
            fileSize: fileSize,
            records: allRecords
        )

        return allRecords
    }
}
