// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "XiaomiMouseFix",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MouseCore"),
        .testTarget(name: "MouseCoreTests", dependencies: ["MouseCore"]),
    ],
    swiftLanguageModes: [.v5]
)
