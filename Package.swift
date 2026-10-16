// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Furifont",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "Furifont", targets: ["Furifont"])
    ],
    traits: [
        .trait(name: "BundledFont", description: "Include Furifont Serif VF and its matching reading tables (about 24 MB).")
    ],
    targets: [
        .target(name: "Furifont", dependencies: [
            .target(name: "FurifontResources", condition: .when(traits: ["BundledFont"]))
        ]),
        .target(name: "FurifontResources", resources: [.process("Resources")]),
        .testTarget(name: "FurifontTests", dependencies: ["Furifont"], resources: [.process("Fixtures")]),
        .testTarget(name: "FurifontSwiftUITests", dependencies: ["Furifont"])
    ]
)
