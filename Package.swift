// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacOSTextReplacements",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "trctl", targets: ["trctl"])
    ],
    targets: [
        .target(
            name: "KSPrivateBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "TrctlKit"
        ),
        .executableTarget(
            name: "trctl",
            dependencies: ["KSPrivateBridge", "TrctlKit"]
        ),
        .testTarget(
            name: "KSPrivateBridgeTests",
            dependencies: ["KSPrivateBridge"]
        ),
        .testTarget(
            name: "TrctlKitTests",
            dependencies: ["TrctlKit"]
        )
    ]
)
