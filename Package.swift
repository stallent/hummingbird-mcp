// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hummingbird_mcp",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "ExampleMCPApp", targets: ["ExampleMCPApp"]),
        .library(name: "HummingbirdMCP", targets: ["HummingbirdMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/orlandos-nl/SSEKit.git", from: "1.1.0"),
        .package(url: "https://github.com/stallent/swift-sdk.git", branch: "streamable_server"),
    ],
    targets: [
        .executableTarget(name: "ExampleMCPApp",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "MCP", package: "swift-sdk"),
                .byName(name: "HummingbirdMCP")
            ],
            path: "Sources/App"
        ),
        .target(name: "HummingbirdMCP",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SSEKit", package: "SSEKit"),
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/Library"
        ),
        .testTarget(name: "HummingbirdMCPTests",
            dependencies: [
                .byName(name: "HummingbirdMCP"),
                .product(name: "HummingbirdTesting", package: "hummingbird")
            ],
            path: "Tests/AppTests"
        )
    ]
)
