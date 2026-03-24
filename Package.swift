// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "openrgb-swift",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "OpenRGB",
            targets: ["OpenRGB"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.91.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.7.1"),
    ],
    targets: [
        .target(
            name: "OpenRGB",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes")
            ],
        ),
        .testTarget(
            name: "OpenRGBTests",
            dependencies: [
                "OpenRGB",
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]
}
