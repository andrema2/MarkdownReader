// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkEdit",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "MarkEdit",
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
    ]
)
