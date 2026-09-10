// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacFansKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SMCKit", targets: ["SMCKit"]),
        .library(name: "MacFansCore", targets: ["MacFansCore"]),
    ],
    targets: [
        .target(name: "CSMC"),
        .target(name: "SMCKit", dependencies: ["CSMC"], linkerSettings: [.linkedFramework("IOKit")]),
        .target(name: "MacFansCore"),
        .testTarget(name: "SMCKitTests", dependencies: ["SMCKit"]),
        .testTarget(name: "MacFansCoreTests", dependencies: ["MacFansCore"]),
    ]
)
