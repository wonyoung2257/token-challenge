// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TokenChallenge",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TokenChallenge",
            path: "Sources/TokenChallenge"
        ),
    ]
)
