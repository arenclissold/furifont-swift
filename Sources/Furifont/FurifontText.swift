// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(SwiftUI) && canImport(CoreText)
import CoreText
import SwiftUI

/// Japanese text with Furifont Serif and okurigana-aware furigana, ready to use.
///
/// The Furifont product bundles Furifont Serif VF v0.3.0 and its
/// matching reading tables. No Info.plist entries or manual registration are needed.
/// The original source string is used for accessibility. The view respects Dynamic Type
/// and inherits text color, alignment, selection, and line limits from SwiftUI.
///
///     FurifontText("来ない、来ます、来る。")
///     FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
///     FurifontText("来ない", showsFurigana: false)
@MainActor
public struct FurifontText: View {
    @Environment(\.furifontConfiguration) private var inheritedConfiguration
    private let configuration: FurifontConfiguration?
    private let source: String
    private let weight: Font.Weight
    private let showsFurigana: Bool
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 28

    /// Uses an explicit configuration, the nearest `.furifont(...)` modifier, or bundled Serif.
    /// Size is in points and scales with Dynamic Type.
    public init(_ text: String, size: CGFloat = 28, weight: Font.Weight = .regular,
                showsFurigana: Bool = true, configuration: FurifontConfiguration? = nil) {
        self.configuration = configuration
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
        _ = try FurifontConfiguration.bundled()
    }

    public var body: some View {
        let original = FurifontConfiguration.plain(source)
        Group {
            if let configuration = configuration ?? inheritedConfiguration ?? (try? .bundled()) {
                let font = configuration.makeFont(size: scaledSize, weight: Self.numericWeight(weight),
                                                  showsFurigana: showsFurigana)
                Text(showsFurigana ? configuration.readings.annotateOkurigana(source) : original)
                    .font(Font(font))
                    // Furifont already includes ruby ascent: add only any missing leading.
                    .lineSpacing(max(0, scaledSize * max(1, configuration.lineHeightMultiple) - CTFontGetAscent(font) - CTFontGetDescent(font) - CTFontGetLeading(font)))
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

private struct FurifontConfigurationKey: EnvironmentKey {
    static let defaultValue: FurifontConfiguration? = nil
}

extension EnvironmentValues {
    fileprivate var furifontConfiguration: FurifontConfiguration? {
        get { self[FurifontConfigurationKey.self] }
        set { self[FurifontConfigurationKey.self] = newValue }
    }
}

extension View {
    /// Sets the font, readings, and rendering preferences for descendant `FurifontText` views.
    /// An individual view's explicit `configuration:` takes precedence.
    public func furifont(_ configuration: FurifontConfiguration) -> some View {
        environment(\.furifontConfiguration, configuration)
    }
}
#endif
