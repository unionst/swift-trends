// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "swift-trends",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .library(
            name: "SwiftTrends",
            targets: ["SwiftTrends"])
    ],
    dependencies: [
        .package(url: "https://github.com/unionst/union-chat-source", branch: "main")
    ],
    targets: [
        .target(
            name: "SwiftTrends",
            dependencies: [
                .product(name: "UnionChat", package: "union-chat-source")
            ],
            path: "Sources/SwiftTrends"
        )
    ]
)
