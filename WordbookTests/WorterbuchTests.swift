//
//  WorterbuchTests.swift
//  WordbookTests
//
//  Pins the persisted-format guarantees for the `Worterbuch` model so that
//  upgrading the app from a pre-language-pair build does not lose data.
//

import XCTest
@testable import Wordbook

final class WorterbuchTests: XCTestCase {

    // MARK: - Backwards-compat decode

    // A Worterbuch persisted by the previous app version (which had no
    // `targetLanguage` field) must still decode under the new schema. The
    // missing field falls back to `.german`, matching the previous hardcoded
    // German↔English behavior.
    func testDecodeLegacyJSONWithoutTargetLanguageDefaultsToGerman() throws {
        let id = UUID()
        let legacyJSON = """
        {
          "id": "\(id.uuidString)",
          "name": "Tiere",
          "key": "phrases_animals"
        }
        """.data(using: .utf8)!

        let buch = try JSONDecoder().decode(Worterbuch.self, from: legacyJSON)

        XCTAssertEqual(buch.id, id)
        XCTAssertEqual(buch.name, "Tiere")
        XCTAssertEqual(buch.key, "phrases_animals")
        XCTAssertEqual(buch.targetLanguage, .german)
    }

    func testDecodeLegacyArrayOfWorterbuchsAllDefaultToGerman() throws {
        // The current persistence helper for phrases stores `[Phrase]` blobs;
        // if/when the same pattern is used for Worterbuchs, an array of legacy
        // entries must round-trip cleanly.
        let id1 = UUID()
        let id2 = UUID()
        let legacyJSON = """
        [
          { "id": "\(id1.uuidString)", "name": "A", "key": "phrases_a" },
          { "id": "\(id2.uuidString)", "name": "B", "key": "phrases_b" }
        ]
        """.data(using: .utf8)!

        let buchs = try JSONDecoder().decode([Worterbuch].self, from: legacyJSON)

        XCTAssertEqual(buchs.count, 2)
        XCTAssertEqual(buchs.map(\.targetLanguage), [.german, .german])
    }

    // MARK: - Round-trip with new field

    func testRoundTripPreservesNonDefaultTargetLanguage() throws {
        let original = Worterbuch(name: "Cuisine", key: "phrases_cuisine", targetLanguage: .french)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Worterbuch.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.key, original.key)
        XCTAssertEqual(decoded.targetLanguage, .french)
    }

    func testRoundTripWithEveryLanguageCase() throws {
        // Guards against accidentally breaking Codable on any Language case
        // (e.g. by changing rawValues used as locale identifiers).
        for language in Language.allCases {
            let original = Worterbuch(name: language.displayName, key: "k_\(language.rawValue)", targetLanguage: language)
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Worterbuch.self, from: encoded)
            XCTAssertEqual(decoded.targetLanguage, language, "Round-trip failed for \(language)")
        }
    }

    // MARK: - Convenience init

    func testInitDefaultsTargetLanguageToGerman() {
        let buch = Worterbuch(name: "n", key: "k")
        XCTAssertEqual(buch.targetLanguage, .german)
    }

    func testInitAcceptsExplicitTargetLanguage() {
        let buch = Worterbuch(name: "n", key: "k", targetLanguage: .japanese)
        XCTAssertEqual(buch.targetLanguage, .japanese)
    }

    // MARK: - Persistence + legacy migration

    private func clearPersistence() {
        UserDefaults.standard.removeObject(forKey: worterbuchsKey)
        UserDefaults.standard.removeObject(forKey: "phrases")
    }

    func testLoadWorterbuchsReturnsEmptyWhenNothingPersistedAndNoLegacyData() {
        clearPersistence()
        defer { clearPersistence() }
        XCTAssertEqual(loadWorterbuchs(), [])
    }

    // The migration hinge: a user upgrading from a build that only knew about
    // the default "phrases" bucket must see their existing translations show
    // up as a wordbook the moment the new WorterbuchListView appears.
    func testLoadWorterbuchsSeedsDefaultGermanFromLegacyPhrasesData() {
        clearPersistence()
        defer { clearPersistence() }
        save(
            [Phrase(id: "Hund", translation: "dog", createdAt: Date())],
            for: "phrases"
        )

        let loaded = loadWorterbuchs()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Default")
        XCTAssertEqual(loaded.first?.key, "phrases")
        XCTAssertEqual(loaded.first?.targetLanguage, .german)
    }

    // If the user has already created their own wordbooks, the seeded Default
    // must NOT appear (we only seed when nothing else is persisted).
    func testLoadWorterbuchsPrefersPersistedOverLegacyMigration() {
        clearPersistence()
        defer { clearPersistence() }
        save(
            [Phrase(id: "Hund", translation: "dog", createdAt: Date())],
            for: "phrases"
        )
        let userBuch = Worterbuch(name: "My Spanish", key: "phrases_spanish", targetLanguage: .spanish)
        saveWorterbuchs([userBuch])

        let loaded = loadWorterbuchs()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "My Spanish")
        XCTAssertEqual(loaded.first?.targetLanguage, .spanish)
    }

    func testSaveWorterbuchsRoundTripsThroughLoad() {
        clearPersistence()
        defer { clearPersistence() }

        let original = [
            Worterbuch(name: "A", key: "phrases_a", targetLanguage: .french),
            Worterbuch(name: "B", key: "phrases_b", targetLanguage: .japanese),
        ]
        saveWorterbuchs(original)

        let loaded = loadWorterbuchs()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.map(\.name), ["A", "B"])
        XCTAssertEqual(loaded.map(\.targetLanguage), [.french, .japanese])
    }
}
