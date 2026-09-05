// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Canopy",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Canopy",
            path: "Sources/Canopy"
        )
    ]
)
