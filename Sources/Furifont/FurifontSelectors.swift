// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT

/// Unicode selectors supported by Furifont: VS225 hides ruby, VS226–VS240 select readings.
enum FurifontSelectors {
    static let hidden: UInt32 = 0xE01E0
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
}
