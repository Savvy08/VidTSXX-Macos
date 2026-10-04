// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VidTSX",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VidTSX",
            targets: ["VidTSX"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VidTSX",
            dependencies: [],
            path: "Sources/VidTSX",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
