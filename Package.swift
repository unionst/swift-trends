// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "swift-trends",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SwiftTrends",
            targets: ["SwiftTrends"])
    ],
    dependencies: [
        .package(path: "../union-chat-source")
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
