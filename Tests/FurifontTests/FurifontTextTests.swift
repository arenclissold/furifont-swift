#if canImport(CoreText) && canImport(SwiftUI)
import SwiftUI
import Testing
import Furifont

struct FurifontTextTests {
    @MainActor @Test func viewSupportsDefaultAndCustomOptions() throws {
        let custom = FurifontConfiguration(fontName: "HiraginoSans-W3", readings: try testReadings())
        _ = FurifontText("来ない", configuration: custom)
        _ = VStack { FurifontText("来ない") }.furifont(custom)
        _ = FurifontText("来ない")
        _ = FurifontText("来ない", size: 32, weight: .medium, showsFurigana: false)
            .foregroundStyle(.blue)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .dynamicTypeSize(.accessibility1)
    }
}
#endif
