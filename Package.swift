// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMAssetExporter",
    products: [
        .library(
            name: "SPMAssetExporter",
            targets: ["SPMAssetExporter"]
      ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SPMAssetExporter",
            dependencies: []
      ),
    ]
)
