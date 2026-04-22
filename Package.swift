// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GiggleTouch",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GiggleTouch",
            path: "Sources/GiggleTouch"
        )
    ]
)
