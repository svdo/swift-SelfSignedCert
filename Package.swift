// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SelfSignedCert",
    platforms: [
        .macOS(.v10_14), .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SelfSignedCert",
            targets: ["SelfSignedCert"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/iosdevzone/IDZSwiftCommonCrypto", from: "0.13.1"),
        .package(name: "SecurityExtensions", url: "https://github.com/svdo/swift-SecurityExtensions", from: "4.0.1"),
        .package(name: "SwiftBytes", url: "https://github.com/dapperstout/swift-bytes.git", from: "0.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SelfSignedCert",
            dependencies: ["IDZSwiftCommonCrypto", "SecurityExtensions", "SwiftBytes"],
            path: "SelfSignedCert",
            exclude: ["Info.plist"]
        )
    ]
)
