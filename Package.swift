// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Keypop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "keypop", targets: ["keypop"]),
    ],
    targets: [
        .target(
            name: "KSPrivateBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "KeypopKit"
        ),
        .executableTarget(
            name: "keypop",
            dependencies: ["KSPrivateBridge", "KeypopKit"]
        ),
        .testTarget(
            name: "KSPrivateBridgeTests",
            dependencies: ["KSPrivateBridge"]
        ),
        .testTarget(
            name: "KeypopKitTests",
            dependencies: ["KeypopKit"]
        ),
    ]
)
