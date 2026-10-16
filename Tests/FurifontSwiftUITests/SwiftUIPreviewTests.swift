#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import Testing
import UIKit
import Furifont

struct SwiftUIPreviewTests {
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
        func png(_ view: some View) throws -> Data {
            let renderer = ImageRenderer(content: view.frame(width: 200)
                .foregroundStyle(.black).background(.white).preferredColorScheme(.light))
            renderer.scale = 2
            return try #require(renderer.uiImage?.pngData())
        }
        let source = "来ない、来ます、来る。"
        let baseline = try png(FurifontText(source))
        let explicit = try png(FurifontText(source, configuration: custom))
        let inherited = try png(FurifontText(source).furifont(custom))
        let overridden = try png(FurifontText(source, configuration: standard).furifont(custom))
        #expect(explicit == inherited)
        #expect(overridden == baseline)
        #expect(explicit != baseline)
    }

    #else
    @MainActor @Test func withoutBundledFontRendersPlainSource() throws {
        guard #available(iOS 16.0, tvOS 16.0, *) else { return }
        func png(_ view: some View) throws -> Data {
            let renderer = ImageRenderer(content: view.frame(width: 200)
                .foregroundStyle(.black).background(.white).preferredColorScheme(.light))
            return try #require(renderer.uiImage?.pngData())
        }
        let actual = try png(FurifontText("来\u{E01E5}ない"))
        let plain = try png(Text("来ない").font(.system(size: 28, weight: .regular, design: .serif)))
        #expect(actual == plain)
    }
    #endif

}
#endif
