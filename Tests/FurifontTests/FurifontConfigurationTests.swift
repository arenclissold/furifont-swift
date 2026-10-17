#if canImport(CoreText) && canImport(SwiftUI)
import CoreText
import Foundation
import Testing
@testable import Furifont

struct FurifontConfigurationTests {
    @Test func invalidCustomFontFailsExplicitly() throws {
        let readings = try testReadings()
        #expect(throws: FurifontConfiguration.LoadingError.fileURLRequired) {
            try FurifontConfiguration(
                fontURL: URL(string: "https://example.com/font.ttf")!, readings: readings)
        }
        do {
            _ = try FurifontConfiguration(
                fontURL: URL(fileURLWithPath: "/missing-font.ttf"), readings: readings)
            Issue.record("Expected a missing font error")
        } catch let error as FurifontConfiguration.LoadingError {
            guard case .unreadableResource(let path, let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(path == "/missing-font.ttf")
            #expect(!reason.isEmpty)
        }
        #expect(throws: FurifontConfiguration.LoadingError.resourceNotFound("Missing.ttf")) {
            try FurifontConfiguration(fontResource: "Missing", bundle: .module)
        }
    }

    @Test func malformedFontFailsWithRecoveryGuidance() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ttf")
        try Data("not a font".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let readings = try testReadings()
        #expect(throws: FurifontConfiguration.LoadingError.invalidFont) {
            try FurifontConfiguration(fontURL: url, readings: readings)
        }
    }

    @Test func customReadingsAndRegisteredFontsNeedNoBundledAssets() throws {
        let readings = try testReadings()
        let native = CTFontCreateWithName("HiraginoSans-W3" as CFString, 28, nil)
        let name = CTFontCopyPostScriptName(native) as String
        let configuration = FurifontConfiguration(fontName: name, readings: readings)
        #expect(configuration.readings.annotateOkurigana("来ない") == "来\u{E01E2}ない")
        #expect(CTFontCopyPostScriptName(configuration.makeFont(size: 32)) as String == name)
        #expect(CTFontGetSize(configuration.makeFont(size: 32)) == 32)
    }

    #if !BundledFont
    @Test func bundledFontIsExplicitlyUnavailable() {
        #expect(throws: FurifontConfiguration.LoadingError.bundledFontNotEnabled) {
            try FurifontConfiguration.bundled()
        }
        #expect(throws: FurifontConfiguration.LoadingError.bundledFontNotEnabled) {
            try FurifontText.prepare()
        }
    }
    #endif
}
#endif
