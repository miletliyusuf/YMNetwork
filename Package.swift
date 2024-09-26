// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YMNetwork",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "YMNetwork",
            targets: ["YMNetwork"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YMNetwork",
            dependencies: [],
	    path: "./YMNetwork"
	    ),
        .testTarget(
            name: "YMNetworkTests",
            dependencies: ["YMNetwork"]),
    ]
)
