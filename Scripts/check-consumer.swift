// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
import Foundation

// Build a separate consumer so optional resources cannot leak in through test targets.
let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.isEmpty || arguments == ["--bundled-font"] else {
    fatalError("Usage: swift Scripts/check-consumer.swift [--bundled-font]")
}
let bundled = !arguments.isEmpty
let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let root = FileManager.default.temporaryDirectory.appendingPathComponent("furifont-consumer-\(UUID())")
try FileManager.default.createDirectory(
    at: root.appendingPathComponent("Sources/Consumer"), withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }

let manifest = """
    // swift-tools-version: 6.2
    import PackageDescription
    let package = Package(name: "Consumer", platforms: [.macOS(.v12)], dependencies: [
        .package(path: \(String(reflecting: repository.path)), traits: \(bundled ? "[\"BundledFont\"]" : "[]"))
    ], targets: [.executableTarget(name: "Consumer", dependencies: [
        .product(name: "Furifont", package: \(String(reflecting: repository.lastPathComponent)))
    ])])
    """
let fontCheck =
    bundled
    ? """
    let configuration = try FurifontConfiguration.bundled()
    precondition(configuration.readings.annotateOkurigana("来ない") == "来\\u{E01E5}ない")
    """
    : """
    do {
        _ = try FurifontConfiguration.bundled()
        fatalError("Bundled font unexpectedly available")
    } catch FurifontConfiguration.LoadingError.bundledFontNotEnabled {
        print("No bundled font, as expected")
    }
    """
let source = """
    import Furifont
    let readings = try FurifontReadings(
        lists: .init(kanji: ["来": ["らい", "こ"]], words: [:], lone: ["来": "らい"]),
        pairs: ["来": ["こ": ["ない"]]])
    precondition(readings.annotateOkurigana("来ない") == "来\\u{E01E2}ない")
    #if canImport(CoreText)
    \(fontCheck)
    #endif
    """
try manifest.write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
try source.write(
    to: root.appendingPathComponent("Sources/Consumer/main.swift"), atomically: true, encoding: .utf8)

let build = Process()
build.executableURL = URL(fileURLWithPath: "/usr/bin/env")
build.arguments = ["swift", "run", "--package-path", root.path, "-c", "release"]
try build.run()
build.waitUntilExit()
guard build.terminationStatus == 0 else {
    fatalError("Consumer build failed with exit status \(build.terminationStatus)")
}

let output = root.appendingPathComponent(".build")
let files =
    FileManager.default.enumerator(at: output, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
for name in ["FurifontSerifVF.ttf", "FurifontSerifVF.ivs.json", "okurigana.json"] {
    let included = files.contains { $0.lastPathComponent == name }
    precondition(included == bundled, "Unexpected resource inclusion for \(name): \(included)")
}
print("Consumer verified: bundled resources \(bundled ? "included" : "omitted")")
