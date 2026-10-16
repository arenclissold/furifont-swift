#if canImport(CoreText) && canImport(SwiftUI)
import CoreText
import Foundation
import Testing
@testable import Furifont

#if BundledFont
struct BundledFontTests {
    @Test func bundledResourcesLoadAndRegisterWithoutSetup() throws {
        try FurifontText.prepare()
        try FurifontText.prepare()
        let configuration = try FurifontConfiguration.bundled()
        #expect(configuration.fontName == "FurifontSerifVF-ExtraLight")
        let font = CTFontCreateWithName(configuration.fontName as CFString, 28, nil)
        #expect(CTFontCopyPostScriptName(font) as String == configuration.fontName)
        #expect(
            configuration.readings.annotateOkurigana("来ない、来ます、来る")
                == "来\u{E01E5}ない、来\u{E01E2}ます、来\u{E01E4}る")
    }

    @Test func registeringTheBundledFontAgainIsSafe() throws {
        _ = try FurifontConfiguration.bundled()
        let second = try FurifontConfiguration(
            fontResource: "FurifontSerifVF", bundle: FurifontConfiguration.bundledResources)
        #expect(second.fontName == "FurifontSerifVF-ExtraLight")
    }

    @MainActor @Test func regularAndBoldUseRequestedVariableFontWeights() throws {
        let configuration = try FurifontConfiguration.bundled()
        for (weight, value) in [(400.0, 400.0), (700.0, 700.0)] {
            let font = configuration.makeFont(size: 28, weight: weight, showsFurigana: true)
            let variation = try #require(CTFontCopyVariation(font) as? [NSNumber: NSNumber])
            #expect(variation[NSNumber(value: 0x7767_6874)]?.doubleValue == value)
            #expect((CTFontCopyPostScriptName(font) as String).hasPrefix("FurifontSerifVF-"))
        }
    }

    @MainActor @Test func hidingRubyChangesGlyphsWhileKeepingFontAndMetrics() throws {
        let configuration = try FurifontConfiguration.bundled()
        let shown = configuration.makeFont(size: 28, weight: 400, showsFurigana: true)
        let hidden = configuration.makeFont(size: 28, weight: 400, showsFurigana: false)
        #expect(glyphs(shown) != glyphs(hidden))
        #expect(
            CTFontCopyPostScriptName(shown) as String == CTFontCopyPostScriptName(hidden) as String)
        #expect(CTFontGetAscent(shown) == CTFontGetAscent(hidden))
        #expect(CTFontGetDescent(shown) == CTFontGetDescent(hidden))
    }

    @Test func customFontUsesItsOwnTablesAndPreferences() throws {
        let readings = try testReadings()
        let url = try #require(
            FurifontConfiguration.bundledResources.url(
                forResource: "FurifontSerifVF", withExtension: "ttf"))
        var custom = try FurifontConfiguration(fontURL: url, readings: readings)
        custom.variations = ["wght": 600, "invalid": 900]
        custom.features = ["ss01": 1, "bad": 1]
        custom.lineHeightMultiple = 2
        #expect(custom.readings.annotateOkurigana("来ない") == "来\u{E01E2}ない")
        #expect(
            try FurifontConfiguration.bundled().readings.annotateOkurigana("来ない") == "来\u{E01E5}ない")
        let font = custom.makeFont(size: 32, weight: 400)
        let variations = try #require(CTFontCopyVariation(font) as? [NSNumber: NSNumber])
        #expect(variations[NSNumber(value: 0x7767_6874)]?.doubleValue == 600)
        let expected = try FurifontConfiguration.bundled().makeFont(size: 32, weight: 600)
        #expect(glyphs(font) == glyphs(expected))  // ss01 cannot override showsFurigana.
        #expect(CTFontGetSize(font) == 32)
        #expect(try FurifontConfiguration.bundled().variations.isEmpty)
    }
}

private func glyphs(_ font: CTFont) -> [CGGlyph] {
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(
            string: "今日",
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font
            ]))
    return (CTLineGetGlyphRuns(line) as! [CTRun]).flatMap { run in
        var result = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
        CTRunGetGlyphs(run, CFRange(), &result)
        return result
    }
}
#endif
#endif
