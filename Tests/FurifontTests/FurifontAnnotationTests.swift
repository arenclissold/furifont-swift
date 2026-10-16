import Foundation
import Testing
@testable import Furifont

struct FurifontAnnotationTests {
    private func readings() throws -> FurifontReadings {
        try FurifontReadings(
            lists: .init(
                kanji: [
                    "来": ["らい", "き", "く", "こ"], "食": ["しょく", "た"],
                    "今": ["こん", "いま"], "日": ["ひ", "にち"], "𠮷": ["よし", "きち"],
                ],
                words: ["今日": ["今日[きょう]", "今[こん]日[にち]"]], lone: [:]),
            pairs: ["来": ["こ": ["ない"], "き": ["ます"], "く": ["る"]]])
    }

    @Test func explicitWordsAndKanjiCombineWithAutomaticReadings() throws {
        let display = try readings().annotateReadings("今日[こんにち]は食[た]べる。来ない、来[き]ます。")
        #expect(display == "今\u{E01E2}日は食\u{E01E2}べる。来\u{E01E4}ない、来\u{E01E2}ます。")
    }

    @Test func explicitReadingsOverrideFollowingOkurigana() throws {
        let readings = try readings()
        #expect(readings.annotateOkurigana("来ない") == "来\u{E01E4}ない")
        #expect(readings.annotateReadings("来[く]ない") == "来\u{E01E3}ない")
        #expect(readings.annotateReadings("今[こん]日[にち]") == "今\u{E01E1}日\u{E01E2}")
    }

    @Test func partialAnnotationsKeepAFontShapingBoundary() throws {
        #expect(try readings().annotateReadings("今[こん]日") == "今\u{E01E1}\u{200C}日")
    }

    @Test func emptyAndUnsupportedReadingsHideEveryKanjiInTheAnnotation() throws {
        let readings = try readings()
        let hidden = "今\u{E01E0}日\u{E01E0}"
        #expect(readings.annotateReadings("今日[]") == hidden)
        #expect(readings.annotateReadings("今日[とくべつ]") == hidden)
        #expect(readings.annotateReadings("来[]ない、来[unknown]ない") == "来\u{E01E0}ない、来\u{E01E0}ない")
    }

    @Test func plainTextOmitsMarkupReadingsAndSelectors() {
        let content = FurifontAnnotatedText("🗾今日[こんにち]は、お茶[ちゃ]。来\u{E01E4}ない [note]")
        #expect(content.plainText == "🗾今日は、お茶。来ない [note]")
        #expect(FurifontAnnotatedText("").plainText.isEmpty)
    }

    @Test func verbatimTextKeepsBracketsLiteral() throws {
        let source = "今日[こんにち] and [note]"
        let content = FurifontAnnotatedText(verbatim: source)
        #expect(content.plainText == source)
        #expect(content.rendered(using: try readings()) == source)
    }

    @Test(arguments: ["今日[こんにち", "今日[[こんにち]]", "[今日[こんにち]]", "note[ 今日[こんにち] ]", "今日[こん\nにち]"])
    func malformedAndNestedAnnotationsStayLiteral(_ source: String) throws {
        let content = FurifontAnnotatedText(source)
        let readings = try readings()
        #expect(content.plainText == source)
        #expect(content.rendered(using: readings) == readings.annotateOkurigana(source))
    }

    @Test func preservesUnrelatedBracketsAndResumesAfterThem() throws {
        let source = "English [note]、今日[こんにち]。かな[かな]"
        #expect(try readings().annotateReadings(source) == "English [note]、今\u{E01E2}日。かな[かな]")
    }

    @Test func supplementaryKanjiAndExistingSelectorsAreHandledWithoutDuplication() throws {
        let readings = try readings()
        let display = readings.annotateReadings("🗾𠮷[きち]だ、来\u{E01E4}[く]ない、来\u{E01E2}ます")
        #expect(display == "🗾𠮷\u{E01E2}だ、来\u{E01E3}ない、来\u{E01E2}ます")
        #expect(readings.annotateReadings(display) == display)
    }
}
