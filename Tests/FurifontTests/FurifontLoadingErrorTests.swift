import Foundation
import Testing
import Furifont

struct FurifontLoadingErrorTests {
    @Test func readingErrorsExplainTheProblemAndRecovery() {
        let errors: [FurifontReadings.LoadingError] = [
            .unsupportedFont, .fileURLsRequired, .resourceNotFound("Example.ivs.json"),
            .unreadableResource("/tables/okurigana.json", reason: "Access denied"),
            .invalidResource("Example.ivs.json", reason: "Missing kanji"),
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.recoverySuggestion?.isEmpty == false)
            #expect(error.localizedDescription == error.errorDescription)
        }
        #expect(errors[2].localizedDescription.contains("Example.ivs.json"))
        #expect(errors[2].recoverySuggestion?.contains("Bundle.module") == true)
        #expect(errors[3].localizedDescription.contains("/tables/okurigana.json"))
        #expect(errors[3].localizedDescription.contains("Access denied"))
        #expect(errors[4].localizedDescription.contains("Missing kanji"))
    }

    @Test func invalidReadingsIdentifyTheTableAndSchemaLocation() throws {
        do {
            _ = try FurifontReadings(
                readingsData: Data(#"{"kanji":{"来":42},"words":{},"lone":{},"salt":true}"#.utf8),
                okuriganaData: Data("{}".utf8))
            Issue.record("Expected a reading table error")
        } catch let error as FurifontReadings.LoadingError {
            guard case .invalidResource(let name, let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(name == ".ivs.json")
            #expect(reason.contains("kanji.来"))
            #expect(error.recoverySuggestion?.contains("packed okurigana.json") == true)
        }
    }

    @Test(arguments: [
        (#"{}"#, "kanji"),
        (#"{"kanji":null,"words":{},"lone":{},"salt":true}"#, "kanji"),
    ])
    func missingAndNullFieldsIdentifyTheirSchemaLocation(_ input: String, _ field: String) throws {
        do {
            _ = try FurifontReadings(
                readingsData: Data(input.utf8), okuriganaData: Data("{}".utf8))
            Issue.record("Expected a schema error")
        } catch let error as FurifontReadings.LoadingError {
            guard case .invalidResource(let name, let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(name == ".ivs.json")
            #expect(reason.contains(field))
        }
    }

    @Test func invalidOkuriganaIdentifiesItsOwnTable() throws {
        let lists = FurifontReadings.Lists(kanji: [:], words: [:], lone: [:])
        do {
            _ = try FurifontReadings(
                readingsData: JSONEncoder().encode(lists), okuriganaData: Data("not JSON".utf8))
            Issue.record("Expected an okurigana table error")
        } catch let error as FurifontReadings.LoadingError {
            guard case .invalidResource(let name, _) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(name == "okurigana.json")
        }
    }

    @Test func fileErrorsPreserveCustomPathsAndDecodingDetails() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let readingsURL = directory.appendingPathComponent("Custom.ivs.json")
        let okuriganaURL = directory.appendingPathComponent("custom-pairs.json")
        let lists = FurifontReadings.Lists(kanji: [:], words: [:], lone: [:])
        try JSONEncoder().encode(lists).write(to: readingsURL)
        do {
            _ = try FurifontReadings(readingsURL: readingsURL, okuriganaURL: okuriganaURL)
            Issue.record("Expected a missing table error")
        } catch let error as FurifontReadings.LoadingError {
            guard case .unreadableResource(let path, let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(path == okuriganaURL.path)
            #expect(!reason.isEmpty)
        }
        try Data(#"{"来":{"こ":42}}"#.utf8).write(to: okuriganaURL)
        do {
            _ = try FurifontReadings(readingsURL: readingsURL, okuriganaURL: okuriganaURL)
            Issue.record("Expected an invalid table error")
        } catch let error as FurifontReadings.LoadingError {
            guard case .invalidResource(let path, let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(path == okuriganaURL.path)
            #expect(reason.contains("来.こ"))
        }
    }

    #if canImport(CoreText)
    @Test func fontErrorsExplainTheProblemAndRecovery() {
        let errors: [FurifontConfiguration.LoadingError] = [
            .bundledFontNotEnabled, .fileURLRequired, .resourceNotFound("Custom.otf"),
            .invalidFont, .registrationFailed("System registration reason"),
            .unreadableResource("/fonts/Custom.ttf", reason: "File missing"),
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.recoverySuggestion?.isEmpty == false)
            #expect(error.localizedDescription == error.errorDescription)
        }
        #expect(errors[0].localizedDescription.contains("BundledFont"))
        #expect(errors[0].recoverySuggestion?.contains("FurifontConfiguration") == true)
        #expect(errors[2].localizedDescription.contains("Custom.otf"))
        #expect(errors[4].localizedDescription.contains("System registration reason"))
        #expect(errors[5].localizedDescription.contains("/fonts/Custom.ttf"))
    }
    #endif
}
