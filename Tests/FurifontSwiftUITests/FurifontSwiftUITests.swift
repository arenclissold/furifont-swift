#if canImport(SwiftUI) && canImport(CoreText)
import CoreText
import Foundation
import SwiftUI
import Testing
@testable import FurifontSwiftUI

struct FurifontSwiftUITests {
    @Test func bundledResourcesLoadAndRegisterWithoutSetup() throws {
        try FurifontText.prepare()
        try FurifontText.prepare()
        let configuration = try BundledFurifont.configuration.get()
        #expect(configuration.fontName == "FurifontSerifVF-ExtraLight")
        let font = CTFontCreateWithName(configuration.fontName as CFString, 28, nil)
        #expect(CTFontCopyPostScriptName(font) as String == configuration.fontName)
        #expect(configuration.readings.annotateOkurigana("来ない、来ます、来る")
            == "来\u{E01E5}ない、来\u{E01E2}ます、来\u{E01E4}る")
    }

    @Test func registeringTheBundledFontAgainIsSafe() throws {
        _ = try BundledFurifont.configuration.get()
        let second = try BundledFurifont.load()
        #expect(second.fontName == "FurifontSerifVF-ExtraLight")
    }

    @MainActor @Test func regularAndBoldUseRequestedVariableFontWeights() throws {
        let name = try BundledFurifont.configuration.get().fontName
        for (weight, value) in [(Font.Weight.regular, 400.0), (.bold, 700.0)] {
            let font = FurifontText.makeFont(name: name, size: 28, weight: weight, showsFurigana: true)
            let variation = try #require(CTFontCopyVariation(font) as? [NSNumber: NSNumber])
            #expect(variation[NSNumber(value: 0x77676874)]?.doubleValue == value)
            #expect((CTFontCopyPostScriptName(font) as String).hasPrefix("FurifontSerifVF-"))
        }
    }

    @MainActor @Test func hidingRubyChangesGlyphsWhileKeepingFontAndMetrics() throws {
        let name = try BundledFurifont.configuration.get().fontName
        let shown = FurifontText.makeFont(name: name, size: 28, weight: .regular, showsFurigana: true)
        let hidden = FurifontText.makeFont(name: name, size: 28, weight: .regular, showsFurigana: false)
        func glyphs(_ font: CTFont) -> [CGGlyph] {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: "今日", attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font
            ]))
            return (CTLineGetGlyphRuns(line) as! [CTRun]).flatMap { run in
                var result = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(), &result)
                return result
            }
        }
        #expect(glyphs(shown) != glyphs(hidden))
        #expect(CTFontCopyPostScriptName(shown) as String == CTFontCopyPostScriptName(hidden) as String)
        #expect(CTFontGetAscent(shown) == CTFontGetAscent(hidden))
        #expect(CTFontGetDescent(shown) == CTFontGetDescent(hidden))
    }

    @Test func accessibilityAndHiddenTextKeepOriginalCharacters() {
        #expect(BundledFurifont.plain("来\u{E01E5}ない、今\u{E01E2}日") == "来ない、今日")
        #expect(BundledFurifont.plain("かな English 🗾") == "かな English 🗾")
    }

    @MainActor @Test func viewSupportsDefaultAndCustomOptions() {
        _ = FurifontText("来ない")
        _ = FurifontText("来ない", size: 32, weight: .medium, showsFurigana: false)
            .foregroundStyle(.blue)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .dynamicTypeSize(.accessibility1)
    }
}
#endif
