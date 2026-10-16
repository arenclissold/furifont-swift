import Foundation
import Furifont
import Testing

struct FurifontReadingsTests {
    // Synthetic tables exercise the upstream rules without distributing dictionary data.
    private func reader() throws -> FurifontReadings {
        try FurifontReadings(lists: .init(
            kanji: ["来": ["らい", "き", "く", "こ"], "読": ["よ", "どく"], "人": ["じん", "ひと"], "𠮷": ["よし", "きち"]],
            words: ["一人": ["一[いち]人[にん]", "一人[ひとり]"], "今日": ["今日[きょう]", "今[こん]日[にち]"]],
            lone: ["読": "よ"]
        ), pairs: [
            "来": ["こ": ["ない", "な"], "き": ["ます", "た"], "く": ["る"], "": ["に", "なく"]],
            "読": ["よ": ["む"]], "人": ["ひと": ["も"]], "𠮷": ["きち": ["だ"]],
            "一人": ["ひとり": ["も"]], "今日": ["きょう": ["は"]]
        ])
    }

    @Test func correctsSingleKanjiReadings() throws {
        let reader = try reader()
        #expect(reader.annotateOkurigana("来ない、来ます、来る") == "来\u{E01E4}ない、来\u{E01E2}ます、来\u{E01E3}る")
    }

    @Test func longestEndingIncludingAmbiguityWins() throws {
        let reader = try reader()
        #expect(reader.annotateOkurigana("来なかった") == "来\u{E01E4}なかった")
        #expect(reader.annotateOkurigana("来なくて") == "来なくて")
        #expect(reader.annotateOkurigana("来に") == "来に")
    }

    @Test func suppressesDefaultAndUnknownCorrections() throws {
        let reader = try reader()
        #expect(reader.annotateOkurigana("読む、今日は、未知の漢字、かな、English") == "読む、今日は、未知の漢字、かな、English")
        #expect(reader.salt(for: "読", reading: "よ") == 0)
        #expect(reader.salt(for: "今日", reading: "きょう") == 0)
        #expect(reader.salt(for: "来", reading: "しらない") == 0)
    }

    @Test func readsAlternateWordsFromBracketNotation() throws {
        let reader = try reader()
        #expect(reader.annotateOkurigana("一人も") == "一\u{E01E2}人も")
        #expect(reader.salt(for: "今日", reading: "こんにち") == 2)
        #expect(reader.annotated("今日", reading: "こんにち") == "今\u{E01E2}日")
    }

    @Test func matchesOnlyWholeKanjiRunsBeforeHiragana() throws {
        let reader = try reader()
        #expect(reader.annotateOkurigana("未来ない 来ナイ 来ない") == "未来ない 来ナイ 来\u{E01E4}ない")
    }

    @Test func reportsOriginalUTF16Ranges() throws {
        let reader = try reader()
        let text = "🗾来ない、一人も"
        let matches = reader.matches(in: text)
        #expect(matches.count == 2)
        #expect(matches[0].range == NSRange(location: 2, length: 1))
        #expect(matches[0].reading == "こ")
        #expect(matches[0].salt == 4)
        #expect(matches[1].range == NSRange(location: 6, length: 2))
        let range = try #require(Range(matches[1].range, in: text))
        #expect(text[range] == "一人")
    }

    @Test func supportsSupplementaryHanAndMultipleInsertions() throws {
        let reader = try reader()
        let text = "🗾𠮷だ。来ない、一人も。"
        #expect(reader.annotateOkurigana(text) == "🗾𠮷\u{E01E2}だ。来\u{E01E4}ない、一\u{E01E2}人も。")
        #expect(reader.annotated("𠮷", reading: "きち") == "𠮷\u{E01E2}")
    }

    @Test func leavesExistingSelectorsUntouched() throws {
        let reader = try reader()
        let text = reader.annotateOkurigana("来ない、一人も")
        #expect(reader.annotateOkurigana(text) == text)
        #expect(reader.annotateOkurigana("来\u{E01E0}ない") == "来\u{E01E0}ない")
    }

    @Test func explicitReadingAndHideSelectors() throws {
        let reader = try reader()
        #expect(reader.annotated("今日", reading: "きょう") == "今\u{E01E1}日")
        #expect(reader.annotated("今日", reading: "") == "今\u{E01E0}日")
        #expect(reader.annotated("今日", reading: "任意") == nil)
        #expect(reader.annotated("", reading: "") == nil)
    }

    @Test func limitsSelectorsToFifteenReadings() throws {
        let readings = (0..<16).map { "reading\($0)" }
        let reader = try FurifontReadings(lists: .init(kanji: ["字": readings], words: [:], lone: [:]), pairs: [:])
        #expect(reader.selector(for: "字", reading: "reading14")?.value == 0xE01EF)
        #expect(reader.selector(for: "字", reading: "reading15") == nil)
    }

    @Test func loadsJSONWithoutAppOrBundleDependencies() throws {
        let lists = FurifontReadings.Lists(kanji: ["来": ["く", "こ"]], words: [:], lone: [:])
        let pairs = ["来": ["こ": ["ない"]]]
        let reader = try FurifontReadings(readingsData: JSONEncoder().encode(lists), okuriganaData: JSONEncoder().encode(pairs))
        #expect(reader.annotateOkurigana("来ない") == "来\u{E01E2}ない")
    }

    @Test func rejectsUnsupportedFontsAndMalformedJSON() throws {
        #expect(throws: FurifontReadings.LoadingError.unsupportedFont) {
            try FurifontReadings(lists: .init(kanji: [:], words: [:], lone: [:], salt: false), pairs: [:])
        }
        #expect(throws: (any Error).self) {
            try FurifontReadings(readingsData: Data("{}".utf8), okuriganaData: Data("[]".utf8))
        }
        #expect(throws: FurifontReadings.LoadingError.fileURLsRequired) {
            try FurifontReadings(readingsURL: URL(string: "https://example.com/readings.json")!,
                                okuriganaURL: URL(string: "https://example.com/pairs.json")!)
        }
    }

    @Test func loadsLocalResources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let listsURL = directory.appendingPathComponent("font.ivs.json")
        let pairsURL = directory.appendingPathComponent("okurigana.json")
        try JSONEncoder().encode(FurifontReadings.Lists(kanji: ["来": ["こ"]], words: [:], lone: [:])).write(to: listsURL)
        try JSONEncoder().encode(["来": ["こ": ["ない"]]]).write(to: pairsURL)
        let reader = try FurifontReadings(readingsURL: listsURL, okuriganaURL: pairsURL)
        #expect(reader.annotateOkurigana("来ない") == "来\u{E01E1}ない")
    }
}
