import Foundation

actor JSONLParser {
    private var fileCache: [String: FileCacheEntry] = [:]
    private let decoder = JSONDecoder()
    private let claudeProjectsPath: String

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
        let fm = FileManager.default
        var results: [String] = []

        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        while let url = enumerator.nextObject() as? URL {
            if url.pathExtension == "jsonl" {
                results.append(url.path)
            }
        }

        return results
    }

    private func parseFile(at path: String) -> [TokenRecord] {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date,
              let fileSize = attrs[.size] as? UInt64
        else { return [] }

        // Check cache
        if let cached = fileCache[path],
           cached.modificationDate == modDate,
           cached.fileSize == fileSize {
            return cached.records
        }

        // Parse fresh
        guard let data = fm.contents(atPath: path),
              let content = String(data: data, encoding: .utf8)
        else { return [] }

        let lines = content.components(separatedBy: .newlines)
        var records: [TokenRecord] = []

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8)
            else { continue }

            guard let entry = try? decoder.decode(JSONLEntry.self, from: lineData),
                  entry.type == "assistant",
                  let message = entry.message,
                  let usage = message.usage,
                  let timestampStr = entry.timestamp,
                  let date = isoFormatter.date(from: timestampStr) ?? isoFallback.date(from: timestampStr)
            else { continue }

            let total = usage.total
            guard total > 0 else { continue }

            let record = TokenRecord(
                timestamp: date,
                model: message.model ?? "unknown",
                inputTokens: usage.input_tokens ?? 0,
                outputTokens: usage.output_tokens ?? 0,
                cacheCreationTokens: usage.cache_creation_input_tokens ?? 0,
                cacheReadTokens: usage.cache_read_input_tokens ?? 0
            )
            records.append(record)
        }

        // Update cache
        fileCache[path] = FileCacheEntry(
            modificationDate: modDate,
            fileSize: fileSize,
            records: records
        )

        return records
    }
}
