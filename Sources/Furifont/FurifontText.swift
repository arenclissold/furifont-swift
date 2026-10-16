// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(SwiftUI) && canImport(CoreText)
import CoreText
import SwiftUI

/// Japanese text with Furifont Serif and okurigana-aware furigana, ready to use.
///
/// The optional BundledFont package trait includes Furifont Serif VF v0.3.0 and its
/// matching reading tables. No Info.plist entries or manual registration are needed.
/// The base text without annotations is used for accessibility. The view respects Dynamic Type
/// and inherits text color, alignment, selection, and line limits from SwiftUI.
/// Without that trait, supply a custom configuration; otherwise plain text is displayed.
///
///     FurifontText("来ない、来ます、来る。")
///     FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
///     FurifontText("来ない", showsFurigana: false)
///     FurifontText(annotated: "今日[こんにち]は、来[く]る。")
@MainActor
public struct FurifontText: View {
    @Environment(\.furifontConfiguration) private var inheritedConfiguration
    private let configuration: FurifontConfiguration?
    private let content: FurifontAnnotatedText
    private let weight: Font.Weight
    private let showsFurigana: Bool
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 28

    /// Uses an explicit configuration, the nearest `.furifont(...)` modifier, or bundled Serif.
    /// Size is in points and scales with Dynamic Type.
    public init(
        _ text: String, size: CGFloat = 28, weight: Font.Weight = .regular,
        showsFurigana: Bool = true, configuration: FurifontConfiguration? = nil
    ) {
        self.init(
            content: FurifontAnnotatedText(verbatim: text), size: size, weight: weight,
            showsFurigana: showsFurigana, configuration: configuration)
    }

    /// Resolves `漢字[かんじ]` annotations using the selected font's reading tables.
    ///
    /// Explicit readings override okurigana inference; unannotated text still uses inference.
    /// `漢字[]` and unsupported readings display the kanji without ruby. Hidden furigana,
    /// accessibility, and the plain-text fallback omit recognized markup and reading text.
    /// Other brackets and malformed or nested annotations remain literal.
    public init(
        annotated text: String, size: CGFloat = 28, weight: Font.Weight = .regular,
        showsFurigana: Bool = true, configuration: FurifontConfiguration? = nil
    ) {
        self.init(
            content: FurifontAnnotatedText(text), size: size, weight: weight,
            showsFurigana: showsFurigana, configuration: configuration)
    }

    private init(
        content: FurifontAnnotatedText, size: CGFloat, weight: Font.Weight,
        showsFurigana: Bool, configuration: FurifontConfiguration?
    ) {
        self.configuration = configuration
        self.content = content
        self.weight = weight
        self.showsFurigana = showsFurigana
        _scaledSize = ScaledMetric(wrappedValue: max(1, size), relativeTo: .body)
    }

    /// Optionally loads and registers resources before the first view appears.
    ///
    /// The first view otherwise prepares them automatically. Preparation is cached
    /// and safe to call repeatedly or from a background task. If automatic preparation
    /// fails, the view displays plain source text; call this method to handle errors explicitly.
    /// Requires the BundledFont package trait. Custom configurations are prepared by their initializer.
    public nonisolated static func prepare() throws {
        _ = try FurifontConfiguration.bundled()
    }

    public var body: some View {
        let original = content.plainText
        Group {
            if let configuration = configuration ?? inheritedConfiguration ?? (try? .bundled()) {
                let font = configuration.makeFont(
                    size: scaledSize, weight: Self.numericWeight(weight),
                    showsFurigana: showsFurigana)
                Text(showsFurigana ? content.rendered(using: configuration.readings) : original)
                    .font(Font(font))
                    .lineSpacing(configuration.additionalLineSpacing(for: font))
            } else {
                Text(original)
                    .font(.system(size: scaledSize, weight: weight, design: .serif))
            }
        }
        .accessibilityLabel(Text(verbatim: original))
    }

    private static func numericWeight(_ weight: Font.Weight) -> Double {
        switch weight {
        case .ultraLight, .thin: 250
        case .light: 300
        case .medium: 500
        case .semibold: 600
        case .bold: 700
        case .heavy: 800
        case .black: 900
        default: 400
        }
    }
}

#endif
