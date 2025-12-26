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
        )
    ],
    targets: [
        .target(
            name: "App",
            path: "Sources/App"
        )
    ]
)
