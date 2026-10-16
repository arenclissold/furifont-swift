// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
import Foundation

/// Parsed once and reused for display, accessibility, and ruby visibility.
struct FurifontAnnotatedText: Sendable {
    private struct Segment: Sendable {
        let text: String
        let reading: String?
    }

    private static let annotation = try! NSRegularExpression(
        pattern: #"((?:\p{Han}[\x{E01E0}-\x{E01EF}]?)+)\[([^\[\]\r\n]*)\]"#)

    private static let startsWithHan = try! NSRegularExpression(pattern: #"^\p{Han}"#)

    private let segments: [Segment]
    let plainText: String

    init(verbatim text: String) {
        segments = [Segment(text: text, reading: nil)]
        plainText = FurifontSelectors.plain(text)
    }

    init(_ notation: String) {
        var segments: [Segment] = []
        var literalStart = notation.startIndex
        var scannedThrough = notation.startIndex
        var bracketDepth = 0

        for match in Self.annotation.matches(
            in: notation, range: NSRange(notation.startIndex..., in: notation))
        {
            guard let range = Range(match.range, in: notation),
                let base = Range(match.range(at: 1), in: notation),
                let ruby = Range(match.range(at: 2), in: notation)
            else { continue }
            Self.scanBrackets(notation[scannedThrough..<range.lowerBound], depth: &bracketDepth)
            if bracketDepth == 0 {
                if literalStart < range.lowerBound {
                    segments.append(
                        Segment(text: String(notation[literalStart..<range.lowerBound]), reading: nil))
                }
                segments.append(
                    Segment(
                        text: FurifontSelectors.plain(String(notation[base])), reading: String(notation[ruby])
                    ))
                literalStart = range.upperBound
            } else {
                // A candidate inside another bracket pair is literal text, not nested markup.
                Self.scanBrackets(notation[range], depth: &bracketDepth)
            }
            scannedThrough = range.upperBound
        }
        if literalStart < notation.endIndex {
            segments.append(Segment(text: String(notation[literalStart...]), reading: nil))
        }
        self.segments = segments
        plainText = FurifontSelectors.plain(segments.map(\.text).joined())
    }

    func rendered(using readings: FurifontReadings) -> String {
        var selected = ""
        for (index, segment) in segments.enumerated() {
            guard let reading = segment.reading else {
                selected += segment.text
                continue
            }
            if !reading.isEmpty, let value = readings.annotated(segment.text, reading: reading) {
                selected += value
            } else {
                // VS225 suppresses one kanji, so mark every scalar in an unsupported or hidden run.
                selected += FurifontSelectors.suppressRuby(in: segment.text)
            }
            if index + 1 < segments.count {
                let next = segments[index + 1]
                if next.reading == nil,
                    Self.startsWithHan.firstMatch(
                        in: next.text, range: NSRange(next.text.startIndex..., in: next.text)) != nil
                {
                    // Stop a whole-word font rule from consuming the explicitly selected first kanji.
                    selected += "\u{200C}"
                }
            }
        }
        return readings.annotateOkurigana(selected)
    }

    private static func scanBrackets(_ text: Substring, depth: inout Int) {
        for scalar in text.unicodeScalars {
            if scalar == "[" { depth += 1 } else if scalar == "]" { depth = max(0, depth - 1) }
        }
    }
}

extension FurifontReadings {
    /// Resolves `漢字[かんじ]` annotations, then applies okurigana inference to unannotated text.
    ///
    /// Explicit readings take precedence. Empty or unsupported readings hide ruby for the entire
    /// annotated run. Other brackets and malformed or nested annotations remain literal.
    /// Use the matching Furifont to render the returned selectors; retain the original for storage.
    public func annotateReadings(_ notation: String) -> String {
        FurifontAnnotatedText(notation).rendered(using: self)
    }
}
