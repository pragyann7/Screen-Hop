// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenHop",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Screen Hop", targets: ["ScreenHop"])],
    targets: [
        .executableTarget(name: "ScreenHop"),
        .testTarget(name: "ScreenHopTests", dependencies: ["ScreenHop"])
    ]
)
