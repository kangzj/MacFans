// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FanwrightKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SMCKit", targets: ["SMCKit"]),
        .library(name: "FanwrightCore", targets: ["FanwrightCore"]),
    ],
    targets: [
        .target(name: "CSMC"),
        .target(name: "SMCKit", dependencies: ["CSMC"], linkerSettings: [.linkedFramework("IOKit")]),
        .target(name: "FanwrightCore"),
        .testTarget(name: "SMCKitTests", dependencies: ["SMCKit"]),
        .testTarget(name: "FanwrightCoreTests", dependencies: ["FanwrightCore"]),
    ]
)
