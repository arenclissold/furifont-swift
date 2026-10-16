#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import Testing
import UIKit
import Furifont

struct FurifontRenderingTests {
    #if BundledFont
    @MainActor @Test func oneLineSetupRendersWithoutAppFontConfiguration() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let content = VStack(alignment: .leading, spacing: 24) {
            FurifontText("来ない、来ます、来る。")
            FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
            FurifontText("来ない、来ます、来る。", showsFurigana: false)
        }
        .padding(24)
        .frame(width: 390)
        .foregroundStyle(.black)
        .background(.white)
        .preferredColorScheme(.light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        #expect(image.size.width == 390)
        #expect(image.size.height > 0)
        Attachment.record(try #require(image.pngData()), named: "furifont-swiftui-quick-start.png")
    }

    @MainActor @Test func inheritedConfigurationAndExplicitOverrideRenderCorrectly() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let standard = try FurifontConfiguration.bundled()
        var custom = standard
        custom.variations["wght"] = 700
        custom.lineHeightMultiple = 2.4
        let source = "来ない、来ます、来る。"
        let baseline = try renderPNG(FurifontText(source))
        let explicit = try renderPNG(FurifontText(source, configuration: custom))
        let inherited = try renderPNG(FurifontText(source).furifont(custom))
        let overridden = try renderPNG(FurifontText(source, configuration: standard).furifont(custom))
        #expect(explicit == inherited)
        #expect(overridden == baseline)
        #expect(explicit != baseline)
    }

    @MainActor @Test func annotatedViewRendersExplicitSelectorsAndHidesCleanly() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let notation = "今日[こんにち]、来[く]ない。"
        let explicit = try renderPNG(FurifontText(annotated: notation))
        let selected = try renderPNG(FurifontText("今\u{E01E2}日、来\u{E01E4}ない。"))
        let inferred = try renderPNG(FurifontText("今日、来ない。"))
        #expect(explicit == selected)
        #expect(explicit != inferred)
        let hidden = try renderPNG(FurifontText(annotated: notation, showsFurigana: false))
        let plain = try renderPNG(FurifontText("今日、来ない。", showsFurigana: false))
        #expect(hidden == plain)
    }

    @MainActor @Test func partialAnnotationKeepsItsReadingNextToUnannotatedKanji() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let actual = try renderPNG(FurifontText(annotated: "今[こん]日"))
        let separated = try renderPNG(
            HStack(spacing: 0) {
                FurifontText(annotated: "今[こん]")
                FurifontText("日")
            })
        let wholeWord = try renderPNG(FurifontText("今日"))
        #expect(actual == separated)
        #expect(actual != wholeWord)
    }

    @MainActor @Test func emptyAndUnavailableWordReadingsRenderWithoutRuby() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let plain = try renderPNG(FurifontText("今日", showsFurigana: false))
        #expect(try renderPNG(FurifontText(annotated: "今日[]")) == plain)
        #expect(try renderPNG(FurifontText(annotated: "今日[とくべつ]")) == plain)
    }

    #else
    @MainActor @Test func withoutBundledFontRendersPlainSource() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let actual = try renderPNG(FurifontText("来\u{E01E5}ない"))
        let plain = try renderPNG(
            Text("来ない").font(.system(size: 28, weight: .regular, design: .serif)))
        #expect(actual == plain)
    }

    @MainActor @Test func annotatedViewWithoutResourcesUsesCleanPlainText() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        let actual = try renderPNG(FurifontText(annotated: "今日[こんにち] [note]"))
        let plain = try renderPNG(FurifontText("今日 [note]"))
        let literal = try renderPNG(FurifontText("今日[こんにち] [note]"))
        #expect(actual == plain)
        #expect(actual != literal)
    }

    #endif

    @available(iOS 16.0, tvOS 16.0, *)
    @MainActor private func renderPNG(_ view: some View) throws -> Data {
        let renderer = ImageRenderer(
            content: view.frame(width: 200)
                .foregroundStyle(.black).background(.white).preferredColorScheme(.light))
        renderer.scale = 2
        return try #require(renderer.uiImage?.pngData())
    }
}
#endif
