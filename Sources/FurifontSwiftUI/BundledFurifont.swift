// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(CoreText)
import CoreText
import Foundation
import Furifont

/// The resource cache is independent of SwiftUI's main actor so applications can preload it.
enum BundledFurifont {
    struct Configuration: Sendable {
        let fontName: String
        let readings: FurifontReadings
    }

    enum SetupError: Error {
        case missingFont
        case invalidFont
        case registrationFailed(String)
    }

    static let configuration: Result<Configuration, any Error> = Result { try load() }

    static func load() throws -> Configuration {
        guard let url = Bundle.module.url(forResource: "FurifontSerifVF", withExtension: "ttf") else {
            throw SetupError.missingFont
        }
        let readings = try FurifontReadings(fontResource: "FurifontSerifVF", bundle: .module)
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String else {
            throw SetupError.invalidFont
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            guard let failure = error?.takeRetainedValue() else {
                throw SetupError.registrationFailed("Font registration failed without an error description.")
            }
            guard CFErrorGetCode(failure) == CTFontManagerError.alreadyRegistered.rawValue else {
                throw SetupError.registrationFailed(CFErrorCopyDescription(failure) as String)
            }
        }
        return Configuration(fontName: name, readings: readings)
    }

    static func plain(_ text: String) -> String {
        String(text.unicodeScalars.filter { !(0xE01E0...0xE01EF).contains($0.value) })
    }
}
#endif
