// Swift adaptation of @furifont/helper-web v0.3.0 by Anthony Fu.
// Copyright (c) 2025-PRESENT Anthony Fu; Copyright (c) 2026 arenclissold.
// SPDX-License-Identifier: MIT

import Foundation

/// Selects Furifont readings using the hiragana following a complete run of kanji.
///
/// Supply the `.ivs.json` and packed `okurigana.json` belonging to your font build.
/// This value is immutable and safe to reuse across tasks. It performs no networking,
/// font registration, UI rendering, or morphological analysis.
public struct FurifontReadings: Sendable {
    /// The reading lists in a Furifont `.ivs.json` file.
    public struct Lists: Codable, Sendable {
        public let kanji: [String: [String]]
        public let words: [String: [String]]
        public let lone: [String: String]
        public let salt: Bool

        /// Word readings use upstream bracket notation, e.g. `今[こん]日[にち]`.
        public init(
            kanji: [String: [String]], words: [String: [String]],
            lone: [String: String], salt: Bool = true
        ) {
            self.kanji = kanji
            self.words = words
            self.lone = lone
            self.salt = salt
        }
    }

    public enum LoadingError: LocalizedError, Equatable, Sendable {
        /// The font's reading table does not advertise the `salt` feature.
        case unsupportedFont
        /// Resource loading accepts local files only; downloading is the caller's responsibility.
        case fileURLsRequired
        /// A named JSON resource could not be found in the supplied bundle.
        case resourceNotFound(String)
        /// A local resource could not be read. Includes its path and the system's reason.
        case unreadableResource(String, reason: String)
        /// A reading table is not valid JSON in the expected upstream format.
        case invalidResource(String, reason: String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedFont:
                return "The Furifont reading table does not support alternate readings (salt is disabled)."
            case .fileURLsRequired:
                return "Furifont reading tables must be loaded from local file URLs."
            case .resourceNotFound(let name):
                return "The Furifont reading table ‘\(name)’ was not found in the supplied bundle."
            case .unreadableResource(let path, let reason):
                return "Could not read the Furifont table at ‘\(path)’: \(reason)"
            case .invalidResource(let name, let reason):
                return "The Furifont table ‘\(name)’ has an invalid format: \(reason)"
            }
        }

        public var recoverySuggestion: String? {
            switch self {
            case .unsupportedFont:
                return "Use a Furifont build with salt support and its matching .ivs.json table."
            case .fileURLsRequired:
                return
                    "Download the tables first, then pass their local file URLs, or use init(readingsData:okuriganaData:)."
            case .resourceNotFound:
                return
                    "Include the JSON file in your target's resources and check its filename. Pass the bundle that owns it; use your package's Bundle.module for Swift package resources."
            case .unreadableResource:
                return
                    "Check that the file exists and your app can read it. Use the local tables from the same Furifont build as your font."
            case .invalidResource:
                return
                    "Use the matching .ivs.json and packed okurigana.json files from your Furifont build. Pass the font's table as readingsData and the packed okurigana table as okuriganaData."
            }
        }
    }

    /// A reading correction in the original, unmodified input.
    public struct Match: Equatable, Sendable {
        /// UTF-16 offsets, suitable for NSAttributedString. Convert using `Range(range, in: text)`.
        public let range: NSRange
        public let reading: String
        /// The font's `salt` feature value (1...15).
        public let salt: Int
    }

    private struct Ending: Sendable {
        let text: String
        let reading: String
    }

    private let kanjiReadings: [String: [String]]
    private let wordReadings: [String: [String]]
    private let defaultReadings: [String: String]
    private let endings: [String: [Ending]]
    private static let runs = try! NSRegularExpression(
        pattern: #"(?<![\p{Han}\x{E01E0}-\x{E01EF}])\p{Han}+(?=\p{Hiragana})"#)
    private static let ruby = try! NSRegularExpression(pattern: #"\[([^\]]*)\]"#)

    /// Initializes with decoded upstream tables.
    ///
    /// `pairs` maps a kanji run to readings and their following kana:
    /// `["来": ["こ": ["ない"], "き": ["ます"], "": ["に"]]]`.
    /// An empty reading denotes ambiguity and prevents a shorter pair from winning.
    public init(lists: Lists, pairs: [String: [String: [String]]]) throws {
        guard lists.salt else { throw LoadingError.unsupportedFont }
        kanjiReadings = lists.kanji
        wordReadings = lists.words.mapValues { $0.map(Self.readingInNotation) }
        defaultReadings = lists.lone
        self.endings = pairs.mapValues { readings in
            readings.flatMap { reading, suffixes in
                suffixes.filter { !$0.isEmpty }.map { Ending(text: $0, reading: reading) }
            }.sorted {
                if $0.text.utf16.count != $1.text.utf16.count {
                    return $0.text.utf16.count > $1.text.utf16.count
                }
                // Prefer an explicit ambiguity marker if malformed input contains a tie.
                return $0.reading < $1.reading
            }
        }
    }

    /// Decodes the font's `.ivs.json` and packed okurigana JSON.
    /// Throws `LoadingError.invalidResource` for malformed tables, including the decoding location.
    public init(readingsData: Data, okuriganaData: Data) throws {
        try self.init(
            readingsData: readingsData, readingsName: ".ivs.json",
            okuriganaData: okuriganaData, okuriganaName: "okurigana.json")
    }

    /// Loads local resource files. Construct once and reuse, preferably away from the UI thread.
    /// File and JSON errors include the resource path in `LoadingError`.
    public init(readingsURL: URL, okuriganaURL: URL) throws {
        guard readingsURL.isFileURL, okuriganaURL.isFileURL else { throw LoadingError.fileURLsRequired }
        try self.init(
            readingsData: Self.readResource(at: readingsURL), readingsName: readingsURL.path,
            okuriganaData: Self.readResource(at: okuriganaURL), okuriganaName: okuriganaURL.path)
    }

    /// Loads matching JSON files by font resource name from a bundle.
    ///
    /// For `fontResource: "FurifontSerifVF"`, loads `FurifontSerifVF.ivs.json`
    /// and `okurigana.json`. Supply the resource filename stem, not the font's
    /// PostScript name. Use `okuriganaResource` for a differently named packed table.
    public init(
        fontResource: String, bundle: Bundle = .main,
        okuriganaResource: String = "okurigana"
    ) throws {
        guard let readingsURL = bundle.url(forResource: fontResource + ".ivs", withExtension: "json") else {
            throw LoadingError.resourceNotFound(fontResource + ".ivs.json")
        }
        guard let okuriganaURL = bundle.url(forResource: okuriganaResource, withExtension: "json") else {
            throw LoadingError.resourceNotFound(okuriganaResource + ".json")
        }
        try self.init(readingsURL: readingsURL, okuriganaURL: okuriganaURL)
    }

    private init(
        readingsData: Data, readingsName: String, okuriganaData: Data, okuriganaName: String
    ) throws {
        let lists = try Self.decode(Lists.self, from: readingsData, resource: readingsName)
        let pairs = try Self.decode(
            [String: [String: [String]]].self, from: okuriganaData, resource: okuriganaName)
        try self.init(lists: lists, pairs: pairs)
    }

    private static func readResource(at url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw LoadingError.unreadableResource(url.path, reason: error.localizedDescription)
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data, resource: String) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            let context: DecodingError.Context
            let missingKey: String?
            switch error {
            case DecodingError.keyNotFound(let key, let details):
                context = details
                missingKey = key.stringValue
            case DecodingError.typeMismatch(_, let details), DecodingError.valueNotFound(_, let details),
                DecodingError.dataCorrupted(let details):
                context = details
                missingKey = nil
            default:
                throw LoadingError.invalidResource(resource, reason: error.localizedDescription)
            }
            let path = (context.codingPath.map(\.stringValue) + [missingKey].compactMap { $0 }).joined(
                separator: ".")
            let location = path.isEmpty ? "" : " at \(path)"
            throw LoadingError.invalidResource(resource, reason: context.debugDescription + location)
        }
    }

    /// Corrections selected by the longest matching okurigana prefix.
    /// Ambiguous, unsupported, and already-default readings produce no match.
    public func matches(in text: String) -> [Match] {
        Self.runs.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let run = String(text[range])
            let following = text[range.upperBound...]
            guard let ending = endings[run]?.first(where: { following.hasPrefix($0.text) }),
                !ending.reading.isEmpty
            else { return nil }
            let salt = salt(for: run, reading: ending.reading)
            guard salt > 0 else { return nil }
            return Match(range: match.range, reading: ending.reading, salt: salt)
        }
    }

    /// Returns the correction's `salt` value, or zero if unsupported or already the default.
    /// This follows upstream `createOkuriganaReader().saltOf` semantics.
    public func salt(for run: String, reading: String) -> Int {
        guard let index = readingIndex(for: run, reading: reading),
            index >= (run.unicodeScalars.count > 1 ? 1 : 0), defaultReadings[run] != reading
        else { return 0 }
        return index + 1
    }

    /// Inserts a Furifont variation selector after the first scalar of each corrected kanji run.
    ///
    /// The result can be rendered with SwiftUI Text, UILabel, NSTextField, or Core Text.
    /// Keep the original string for search, persistence, and copying: selectors are invisible
    /// but remain part of the returned text. Existing selectors are left untouched.
    public func annotateOkurigana(_ text: String) -> String {
        var result = text
        // Reverse order preserves the original UTF-16 locations as selectors are inserted.
        for match in matches(in: text).reversed() {
            guard let range = Range(match.range, in: result),
                let selector = FurifontSelectors.scalar(forSalt: match.salt)
            else { continue }
            let afterFirst = result.unicodeScalars.index(after: range.lowerBound)
            result.insert(contentsOf: String(selector), at: afterFirst)
        }
        return result
    }

    /// Selects an explicit reading, including a default. Empty reading means VS225 (hide ruby).
    /// Returns nil when the font cannot supply the reading; no reading is invented.
    public func selector(for run: String, reading: String) -> Unicode.Scalar? {
        if reading.isEmpty { return FurifontSelectors.scalar(forSalt: 0) }
        guard let index = readingIndex(for: run, reading: reading) else { return nil }
        return FurifontSelectors.scalar(forSalt: index + 1)
    }

    /// Returns a run with an explicit reading selector, or nil if unsupported or the run is empty.
    /// Unlike `annotateOkurigana`, this does not infer a reading from context.
    public func annotated(_ run: String, reading: String) -> String? {
        guard let first = run.unicodeScalars.first, let selector = selector(for: run, reading: reading) else {
            return nil
        }
        return String(first) + String(selector) + String(run.unicodeScalars.dropFirst())
    }

    private func readingIndex(for run: String, reading: String) -> Int? {
        let readings = run.unicodeScalars.count > 1 ? wordReadings[run] : kanjiReadings[run]
        guard let index = readings?.firstIndex(of: reading), index < FurifontSelectors.maximumReadings else {
            return nil
        }
        return index
    }

    private static func readingInNotation(_ notation: String) -> String {
        let source = notation as NSString
        return ruby.matches(in: notation, range: NSRange(location: 0, length: source.length))
            .map { source.substring(with: $0.range(at: 1)) }.joined()
    }
}
