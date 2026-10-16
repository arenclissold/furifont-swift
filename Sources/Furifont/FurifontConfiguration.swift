// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(CoreText)
import CoreText
import Foundation
#if BundledFont
import FurifontResources
#endif

/// A registered Furifont build, its matching readings, and rendering preferences.
///
/// Construct once and reuse. Custom fonts must be Furifont builds with matching
/// reading tables; this does not add furigana glyphs to ordinary Japanese fonts.
public struct FurifontConfiguration: Sendable {
    public let fontName: String
    public let readings: FurifontReadings

    /// Minimum line height as a multiple of point size. Existing font metrics are preserved.
    public var lineHeightMultiple: Double = 1.7
    /// Four-character OpenType variation tags, such as `wght` or `wdth`.
    /// These override the view's weight. Invalid tags are ignored.
    public var variations: [String: Double] = [:]
    /// Four-character OpenType feature tags. `ss01` is reserved for ruby visibility.
    /// Invalid tags are ignored.
    public var features: [String: Int] = [:]

    public enum LoadingError: Error, Equatable, Sendable {
        /// Enable the BundledFont package trait, or supply a custom configuration.
        case bundledFontNotEnabled
        case fileURLRequired
        case resourceNotFound(String)
        case invalidFont
        case registrationFailed(String)
    }

    /// Uses a font already registered by the application.
    /// The caller is responsible for supplying a valid PostScript name and matching tables.
    public init(fontName: String, readings: FurifontReadings) {
        self.fontName = fontName
        self.readings = readings
    }

    /// Registers a local font and discovers its PostScript name automatically.
    /// Loading or registration errors throw. Registering the same file again is safe.
    public init(fontURL: URL, readings: FurifontReadings) throws {
        try self.init(fontName: Self.registerFont(at: fontURL), readings: readings)
    }

    /// Loads `name.ttf`, `name.ivs.json`, and `okurigana.json` from a bundle.
    /// Use `fontExtension` for OTF builds and `okuriganaResource` for another table filename.
    public init(
        fontResource: String, bundle: Bundle = .main, fontExtension: String = "ttf",
        okuriganaResource: String = "okurigana"
    ) throws {
        guard let url = bundle.url(forResource: fontResource, withExtension: fontExtension) else {
            throw LoadingError.resourceNotFound(fontResource + "." + fontExtension)
        }
        let readings = try FurifontReadings(
            fontResource: fontResource, bundle: bundle,
            okuriganaResource: okuriganaResource)
        try self.init(fontURL: url, readings: readings)
    }

    private static let cachedBundled: Result<Self, any Error> = Result {
        #if BundledFont
        try Self(fontResource: "FurifontSerifVF", bundle: Self.bundledResources)
        #else
        throw LoadingError.bundledFontNotEnabled
        #endif
    }

    /// The bundled Serif VF font and matching tables, loaded once and safe to share across tasks.
    /// Modify a returned copy to customize the bundled preset.
    /// Throws `LoadingError.bundledFontNotEnabled` when the BundledFont trait is disabled.
    public static func bundled() throws -> Self {
        try cachedBundled.get()
    }

    #if BundledFont
    static var bundledResources: Bundle { FurifontResources.bundle }
    #endif

    /// Creates a Core Text font for SwiftUI, UIKit, AppKit, or your own renderer.
    /// Weight uses the OpenType 100–900 scale. Ruby visibility uses Furifont's `ss01` feature.
    public func makeFont(size: CGFloat, weight: Double = 400, showsFurigana: Bool = true) -> CTFont {
        var axes: [NSNumber: Double] = [NSNumber(value: 0x7767_6874): weight]
        for (tag, value) in variations {
            if let identifier = Self.tagIdentifier(tag) { axes[NSNumber(value: identifier)] = value }
        }
        var settings = features.filter { Self.tagIdentifier($0.key) != nil }
        settings["ss01"] = showsFurigana ? 0 : 1
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [
                kCTFontNameAttribute: fontName,
                kCTFontVariationAttribute: axes,
                kCTFontFeatureSettingsAttribute: settings.sorted { $0.key < $1.key }.map { tag, value in
                    [kCTFontOpenTypeFeatureTag: tag, kCTFontOpenTypeFeatureValue: value]
                        as [CFString: Any]
                },
            ] as CFDictionary)
        return CTFontCreateWithFontDescriptor(descriptor, max(1, size), nil)
    }

    private static func tagIdentifier(_ tag: String) -> UInt32? {
        let bytes = Array(tag.utf8)
        guard bytes.count == 4, bytes.allSatisfy({ (0x20...0x7E).contains($0) }) else { return nil }
        return bytes.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    /// Furifont includes ruby in its metrics, so only add missing leading.
    func additionalLineSpacing(for font: CTFont) -> CGFloat {
        let minimumHeight = CTFontGetSize(font) * max(1, lineHeightMultiple)
        let fontHeight = CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font)
        return max(0, minimumHeight - fontHeight)
    }

    private static func registerFont(at url: URL) throws -> String {
        guard url.isFileURL else { throw LoadingError.fileURLRequired }
        guard
            let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL)
                as? [CTFontDescriptor],
            let descriptor = descriptors.first,
            let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
        else {
            throw LoadingError.invalidFont
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            guard let failure = error?.takeRetainedValue() else {
                throw LoadingError.registrationFailed(
                    "Font registration failed without an error description.")
            }
            guard CFErrorGetCode(failure) == CTFontManagerError.alreadyRegistered.rawValue else {
                throw LoadingError.registrationFailed(CFErrorCopyDescription(failure) as String)
            }
        }
        return name
    }
}
#endif
