// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Furifont",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [.library(name: "Furifont", targets: ["Furifont"])],
    targets: [
        .target(name: "Furifont"),
        .testTarget(name: "FurifontTests", dependencies: ["Furifont"])
    ]
)
