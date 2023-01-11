// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let targetCIconvName = "CIconvLinux";
#else
let targetCIconvName = "CIconv";
#endif

let package = Package(
    name: "rmud",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "rmud",
            dependencies: [
                Target.Dependency(stringLiteral: targetCIconvName),
                "Czlib",
                .product(name: "Vapor", package: "vapor"),
                "BSD"
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(
            name: targetCIconvName,
            dependencies: []
        ),
        .target(
            name: "BSD",
            dependencies: []
        ),
        .target(
            name: "Czlib",
            dependencies: []
        )
    ]
)

