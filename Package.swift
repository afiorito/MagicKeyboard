// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "MagicKeyboard",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "MagicKeyboard",
            targets: ["MagicKeyboard"]
        ),
    ],
    targets: [
        .target(
            name: "MagicKeyboard",
            dependencies: []
        ),
        .testTarget(
            name: "MagicKeyboardTests",
            dependencies: ["MagicKeyboard"]
        ),
    ]
)
