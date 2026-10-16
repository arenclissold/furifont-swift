// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(SwiftUI) && canImport(CoreText)
import CoreText
import SwiftUI

/// Japanese text with Furifont Serif and okurigana-aware furigana, ready to use.
///
/// The optional FurifontSwiftUI product bundles Furifont Serif VF v0.3.0 and its
/// matching reading tables. No Info.plist entries or manual registration are needed.
/// The original source string is used for accessibility. The view respects Dynamic Type
/// and inherits text color, alignment, selection, and line limits from SwiftUI.
///
///     FurifontText("来ない、来ます、来る。")
///     FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
///     FurifontText("来ない", showsFurigana: false)
@MainActor
public struct FurifontText: View {
    private let source: String
    private let weight: Font.Weight
    private let showsFurigana: Bool
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 28

    /// Creates text using the bundled Serif font. Size is in points and scales with Dynamic Type.
    public init(_ text: String, size: CGFloat = 28, weight: Font.Weight = .regular,
                showsFurigana: Bool = true) {
        source = text
        self.weight = weight
        self.showsFurigana = showsFurigana
        _scaledSize = ScaledMetric(wrappedValue: max(1, size), relativeTo: .body)
    }

    /// Optionally loads and registers resources before the first view appears.
    ///
    /// The first view otherwise prepares them automatically. Preparation is cached
    /// and safe to call repeatedly or from a background task. If automatic preparation
    /// fails, the view displays plain source text; call this method to handle errors explicitly.
    public nonisolated static func prepare() throws {
        _ = try BundledFurifont.configuration.get()
    }

    public var body: some View {
        let original = BundledFurifont.plain(source)
        Group {
            if case let .success(configuration) = BundledFurifont.configuration {
                let font = Self.makeFont(name: configuration.fontName, size: scaledSize,
                                         weight: weight, showsFurigana: showsFurigana)
                Text(showsFurigana ? configuration.readings.annotateOkurigana(source) : original)
                    .font(Font(font))
                    // Furifont already includes ruby ascent: add only any missing leading.
                    .lineSpacing(max(0, scaledSize * 1.7 - CTFontGetAscent(font) - CTFontGetDescent(font) - CTFontGetLeading(font)))
            } else {
                Text(original)
                    .font(.system(size: scaledSize, weight: weight, design: .serif))
            }
        }
        .accessibilityLabel(Text(verbatim: original))
    }

    static func makeFont(name: String, size: CGFloat, weight: Font.Weight, showsFurigana: Bool) -> CTFont {
        let numericWeight: Double
        switch weight {
        case .ultraLight, .thin: numericWeight = 250
        case .light: numericWeight = 300
        case .medium: numericWeight = 500
        case .semibold: numericWeight = 600
        case .bold: numericWeight = 700
        case .heavy: numericWeight = 800
        case .black: numericWeight = 900
        default: numericWeight = 400
        }
        let descriptor = CTFontDescriptorCreateWithAttributes([
            kCTFontNameAttribute: name,
            kCTFontVariationAttribute: [NSNumber(value: 0x77676874): numericWeight],
            kCTFontFeatureSettingsAttribute: [[
                kCTFontOpenTypeFeatureTag: "ss01",
                kCTFontOpenTypeFeatureValue: showsFurigana ? 0 : 1
            ]]
        ] as CFDictionary)
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }
}
#endif
