// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "3D_Othello",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "CoreLogic",
            targets: ["CoreLogic"]
        )
    ],
    targets: [
        .target(
            name: "App",
            path: "Sources/App"
            name: "CoreLogic",
            path: "Sources/CoreLogic"
        ),
        .testTarget(
            name: "CoreLogicTests",
            dependencies: ["CoreLogic"]
        )
    ]
)
