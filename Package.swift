// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkEdit",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "MarkEdit",
            dependencies: [
                .product(name: "Citadel", package: "Citadel"),
            ],
            path: "MarkdownReader",
            exclude: [
                "Info.plist",
                "MarkdownReader.entitlements",
                "Assets.xcassets",
            ],
            resources: [
                .copy("Resources/highlight"),
            ]
        ),
        .testTarget(
            name: "MarkEditTests",
            dependencies: ["MarkEdit"],
            path: "MarkEditTests"
        ),
    ]
)
