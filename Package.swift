// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacOSTextReplacements",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "trctl", targets: ["trctl"]),
        .executable(name: "trexpand-probe", targets: ["trexpand-probe"]),
        .executable(name: "trexpand", targets: ["trexpand"]),
    ],
    targets: [
        .target(
            name: "KSPrivateBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "TrctlKit"
        ),
        .target(
            name: "TrexpandKit",
            dependencies: ["TrctlKit"]
        ),
        .executableTarget(
            name: "trctl",
            dependencies: ["KSPrivateBridge", "TrctlKit"]
        ),
        .executableTarget(
            name: "trexpand-probe",
            dependencies: ["TrexpandKit", "KSPrivateBridge"]
        ),
        .executableTarget(
            name: "trexpand",
            dependencies: ["TrexpandKit"]
        ),
        .testTarget(
            name: "KSPrivateBridgeTests",
            dependencies: ["KSPrivateBridge"]
        ),
        .testTarget(
            name: "TrctlKitTests",
            dependencies: ["TrctlKit"]
        ),
        .testTarget(
            name: "TrexpandKitTests",
            dependencies: ["TrexpandKit"]
        ),
    ]
)
