// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT

/// Unicode selectors supported by Furifont: VS225 hides ruby, VS226–VS240 select readings.
enum FurifontSelectors {
    private static let hiddenScalar: Unicode.Scalar = "\u{E01E0}"
    static let hidden = hiddenScalar.value
    static let maximumReadings = 15

    static func scalar(forSalt salt: Int) -> Unicode.Scalar? {
        guard (0...maximumReadings).contains(salt) else { return nil }
        return Unicode.Scalar(hidden + UInt32(salt))
    }

    static func plain(_ text: String) -> String {
        String(
            text.unicodeScalars.filter {
                !(hidden...hidden + UInt32(maximumReadings)).contains($0.value)
            })
    }

    /// The caller supplies a run of kanji with existing selectors removed.
    static func suppressRuby(in kanji: String) -> String {
        kanji.unicodeScalars.map { String($0) + String(hiddenScalar) }.joined()
    }
}
