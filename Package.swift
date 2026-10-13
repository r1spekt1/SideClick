// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SideClick",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MouseCore"),
        .executableTarget(name: "SideClick", dependencies: ["MouseCore"]),
        .testTarget(name: "MouseCoreTests", dependencies: ["MouseCore"]),
    ],
    swiftLanguageModes: [.v5]
)
