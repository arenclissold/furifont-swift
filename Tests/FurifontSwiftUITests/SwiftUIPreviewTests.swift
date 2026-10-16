#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import Testing
import UIKit
import FurifontSwiftUI

struct SwiftUIPreviewTests {
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
}
#endif
