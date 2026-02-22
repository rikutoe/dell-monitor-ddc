// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DDCMonitor",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DDCMonitor",
            dependencies: ["DDCControl"],
            path: "Sources/DDCMonitor"
        ),
        .target(
            name: "DDCControl",
            path: "Sources/DDCControl",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
        .testTarget(
            name: "DDCControlTests",
            dependencies: ["DDCControl"],
            path: "Tests/DDCControlTests"
        ),
    ]
)
