import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, url: URL)
        case error

        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate), (.error, .error):
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

    private struct GitHubRelease: Decodable {
        let tag_name: String
        let html_url: String
    }

    func checkForUpdates() async {
        status = .checking

        guard let url = URL(string: "https://api.github.com/repos/wonyoung2257/token-challenge/releases/latest") else {
            status = .error
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                status = .error
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = release.tag_name.hasPrefix("v")
                ? String(release.tag_name.dropFirst())
                : release.tag_name

            if isNewerVersion(latestVersion, than: currentVersion),
               let releaseURL = URL(string: release.html_url) {
                status = .available(version: latestVersion, url: releaseURL)
            } else {
                status = .upToDate
            }
        } catch {
            status = .error
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
