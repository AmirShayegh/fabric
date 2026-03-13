// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Fabric",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "Fabric", targets: ["Fabric"])
    ],
    targets: [
        .target(name: "Fabric", path: "Sources/Fabric")
    ]
)
