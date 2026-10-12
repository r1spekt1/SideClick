// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "XiaomiMouseFix",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MouseCore"),
        .executableTarget(name: "XiaomiMouseFix", dependencies: ["MouseCore"]),
        .testTarget(name: "MouseCoreTests", dependencies: ["MouseCore"]),
    ],
    swiftLanguageModes: [.v5]
)
