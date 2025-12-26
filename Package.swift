// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "3D_Othello",
    platforms: [
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
            name: "CoreLogic",
            path: "Sources/CoreLogic"
        ),
        .testTarget(
            name: "CoreLogicTests",
            dependencies: ["CoreLogic"]
        )
    ]
)
