// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Octowatch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Octowatch",
            path: "Sources/GitHubActionsBar"
        )
    ]
)
