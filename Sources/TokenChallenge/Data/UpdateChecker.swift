import AppKit
import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, url: URL)
        case updating
        case error

        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate),
                (.updating, .updating), (.error, .error):
                return true
            case let (.available(v1, u1), .available(v2, u2)):
                return v1 == v2 && u1 == u2
            default:
                return false
            }
        }
    }

    @Published var status: Status = .idle

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var isBrewInstalled: Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/Caskroom/token-challenge")
            || FileManager.default.fileExists(atPath: "/usr/local/Caskroom/token-challenge")
    }

    private var brewPath: String? {
        ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private struct GitHubRelease: Decodable {
        let tag_name: String
        let html_url: String
    }

    func checkForUpdates() async {
        status = .checking

        guard let url = URL(
            string: "https://api.github.com/repos/wonyoung2257/token-challenge/releases/latest"
        ) else {
            status = .error
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                status = .error
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion =
                release.tag_name.hasPrefix("v")
                ? String(release.tag_name.dropFirst())
                : release.tag_name

            if isNewerVersion(latestVersion, than: currentVersion),
                let releaseURL = URL(string: release.html_url)
            {
                status = .available(version: latestVersion, url: releaseURL)
            } else {
                status = .upToDate
            }
        } catch {
            status = .error
        }
    }

    func performBrewUpgrade() {
        guard let brew = brewPath else { return }

        status = .updating

        let appPath = "/Applications/TokenChallenge.app"

        let script = """
            #!/bin/bash
            while pgrep -x "TokenChallenge" > /dev/null 2>&1; do
                sleep 0.5
            done
            HOMEBREW_NO_AUTO_UPDATE=1 "\(brew)" upgrade --cask token-challenge
            xattr -d com.apple.quarantine "\(appPath)" 2>/dev/null || true
            open "\(appPath)"
            """

        let tempScript = NSTemporaryDirectory() + "tc_update.sh"
        try? script.write(toFile: tempScript, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: tempScript)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [tempScript]
        process.standardOutput = nil
        process.standardError = nil
        try? process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

    private func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
