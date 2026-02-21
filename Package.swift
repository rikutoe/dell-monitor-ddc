// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DDCMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DDCMonitor",
            path: "Sources/DDCMonitor"
        ),
    ]
)
