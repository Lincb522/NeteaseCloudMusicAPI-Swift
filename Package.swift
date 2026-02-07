// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NeteaseCloudMusicAPI",
    platforms: [
        .iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(name: "NeteaseCloudMusicAPI", targets: ["NeteaseCloudMusicAPI"])
    ],
    dependencies: [
        // 属性测试框架
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "NeteaseCloudMusicAPI",
            path: "Sources/NeteaseCloudMusicAPI"
        ),
        .testTarget(
            name: "NeteaseCloudMusicAPITests",
            dependencies: [
                "NeteaseCloudMusicAPI",
                "SwiftCheck"
            ],
            path: "Tests/NeteaseCloudMusicAPITests"
        )
    ]
)
