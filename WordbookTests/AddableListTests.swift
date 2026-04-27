//
//  AddableListTests.swift
//  WordbookTests
//
//  Tests for AddableListReducer.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class AddableListTests: XCTestCase {
    // Tracked per-test so tearDown can clear UserDefaults.
    var key: String = "phrases"

    override func setUp() {
        super.setUp()
        // Per-test unique key so persistence doesn't leak between tests.
        key = "phrases_\(UUID().uuidString)"
        // Clear default key (used by `dataNeedsReload` via `loadData()`).
        UserDefaults.standard.removeObject(forKey: "phrases")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: "phrases")
        super.tearDown()
    }

    private func makeState(data: [Phrase] = [], targetLanguage: Language = .german) -> AddableListReducer.State {
        return AddableListReducer.State(
            data: data,
            key: key,
            targetLanguage: targetLanguage,
            phraseToItemState: { $0 },
            phraseToSearchableString: { "\($0.id) \($0.translation)" }
        )
    }

    // MARK: - Presentation: addNewTapped / cancel

    func testAddNewTappedPresentsNew() async throws {
        let store = TestStore(initialState: makeState()) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addNewTapped)

        XCTAssertEqual(store.state.new, EditPhraseReducer.State())
    }

    func testCancelClearsNewAndEdit() async throws {
        var state = makeState()
        state.new = EditPhraseReducer.State()
        state.edit = EditPhraseReducer.State()
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.cancel)

        XCTAssertNil(store.state.new)
        XCTAssertNil(store.state.edit)
    }

    // MARK: - Save flows

    func testSaveNewInsertsAtTopAndClearsPresentation() async throws {
        var state = makeState()
        state.new = EditPhraseReducer.State()
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Drive the child state via binding so saveNew picks up text/translation.
        await store.send(.add(.presented(.binding(.set(\.text, "foo")))))
        await store.send(.add(.presented(.binding(.set(\.translation, "bar")))))

        await store.send(.saveNew)

        XCTAssertEqual(store.state.allPhrases.count, 1)
        XCTAssertEqual(store.state.allPhrases.first?.id, "foo")
        XCTAssertEqual(store.state.allPhrases.first?.translation, "bar")
        XCTAssertEqual(store.state.displayedPhrases.first?.id, "foo")
        XCTAssertNil(store.state.new)
    }

    func testSaveEditReplacesByIndex() async throws {
        let original = Phrase(id: "foo", translation: "old", createdAt: Date())
        var state = makeState(data: [original])
        state.edit = EditPhraseReducer.State(phrase: original)
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Mutate edit's translation via the child binding.
        await store.send(.edit(.presented(.binding(.set(\.translation, "new")))))

        await store.send(.saveEdit)

        // Note: Phrase.== ignores translation, so we read .translation directly.
        XCTAssertEqual(store.state.allPhrases.count, 1)
        XCTAssertEqual(store.state.allPhrases.first?.id, "foo")
        XCTAssertEqual(store.state.allPhrases.first?.translation, "new")
        XCTAssertNil(store.state.edit)
    }

    // MARK: - editPhrase by id

    func testEditPhraseByIdLoadsState() async throws {
        let phrase = Phrase(id: "foo", translation: "bar", createdAt: Date())
        let state = makeState(data: [phrase])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.editPhrase(id: "foo"))

        XCTAssertEqual(store.state.edit?.phrase?.id, "foo")
        XCTAssertEqual(store.state.edit?.text, "foo")
        XCTAssertEqual(store.state.edit?.translation, "bar")
    }

    func testEditPhraseByIdMissingIsNoop() async throws {
        let phrase = Phrase(id: "foo", translation: "bar", createdAt: Date())
        let state = makeState(data: [phrase])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.editPhrase(id: "missing"))

        XCTAssertNil(store.state.edit)
    }

    // MARK: - removePhrase

    func testRemovePhraseDropsFromAllPhrases() async throws {
        let phraseA = Phrase(id: "foo", translation: "fooT", createdAt: Date(timeIntervalSinceNow: -1))
        let phraseB = Phrase(id: "bar", translation: "barT", createdAt: Date())
        let state = makeState(data: [phraseA, phraseB])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        XCTAssertEqual(store.state.allPhrases.count, 2)

        await store.send(.removePhrase(id: "foo"))

        XCTAssertEqual(store.state.allPhrases.count, 1)
        XCTAssertNil(store.state.allPhrases.first(where: { $0.id == "foo" }))
        XCTAssertNotNil(store.state.allPhrases.first(where: { $0.id == "bar" }))
    }

    // MARK: - Local filter

    func testLocalFilterBindingFiltersDisplayedPhrases() async throws {
        let hund = Phrase(id: "Hund", translation: "dog", createdAt: Date(timeIntervalSinceNow: -1))
        let katze = Phrase(id: "Katze", translation: "cat", createdAt: Date())
        let state = makeState(data: [hund, katze])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.localFilter, "Hun")))

        XCTAssertEqual(store.state.localFilter, "Hun")
        XCTAssertEqual(store.state.displayedPhrases.map(\.id), ["Hund"])
    }

    // MARK: - Sorting

    func testSortByAlphabetSortsAscendingById() async throws {
        // Note: createdAt order is the inverse of alphabetical so we can detect a real sort.
        let katze = Phrase(id: "Katze", translation: "cat", createdAt: Date())
        let hund = Phrase(id: "Hund", translation: "dog", createdAt: Date(timeIntervalSinceNow: -1))
        let state = makeState(data: [katze, hund])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.sortByAlphabet)

        XCTAssertEqual(store.state.sortScheme, .alphabet)
        XCTAssertEqual(store.state.displayedPhrases.map(\.id), ["Hund", "Katze"])
    }

    func testSortByRecentSortsByCreatedAtDescending() async throws {
        let older = Phrase(id: "Apfel", translation: "apple", createdAt: Date(timeIntervalSinceNow: -10))
        let newer = Phrase(id: "Zebra", translation: "zebra", createdAt: Date())
        let state = makeState(data: [older, newer])
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Force into alphabet first to verify sortByRecent flips back.
        await store.send(.sortByAlphabet)
        XCTAssertEqual(store.state.displayedPhrases.map(\.id), ["Apfel", "Zebra"])

        await store.send(.sortByRecent)

        XCTAssertEqual(store.state.sortScheme, .recent)
        // Newer first (descending by createdAt).
        XCTAssertEqual(store.state.displayedPhrases.map(\.id), ["Zebra", "Apfel"])
    }

    // MARK: - dataNeedsReload

    // dataNeedsReload calls `loadData()` (no arg), which reads the DEFAULT
    // "phrases" key — NOT `state.key`. This test documents that behavior:
    // pre-populate the default key and assert reload picks up from there.
    func testDataNeedsReloadReadsFromDefaultPhrasesKey() async throws {
        let stored = [
            Phrase(id: "alpha", translation: "a", createdAt: Date(timeIntervalSinceNow: -2)),
            Phrase(id: "beta", translation: "b", createdAt: Date(timeIntervalSinceNow: -1)),
        ]
        // Write to the default "phrases" key — which is what loadData() reads.
        save(stored, for: "phrases")

        let state = makeState() // empty allPhrases
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        XCTAssertEqual(store.state.allPhrases.count, 0)

        await store.send(.dataNeedsReload)

        XCTAssertEqual(store.state.allPhrases.count, 2)
        XCTAssertNotNil(store.state.allPhrases[id: "alpha"])
        XCTAssertNotNil(store.state.allPhrases[id: "beta"])
    }

    // Skipped: testDidAppear — `.didAppear` kicks off a long-running effect
    // that listens forever on the WatchConnectivity stream. Per task guidance,
    // this is not exercised here.

    // MARK: - targetLanguage

    // Backwards-compat: existing call sites that don't pass `targetLanguage`
    // continue to behave as if the wordbook is German↔English. This is the
    // hinge that protects users who upgrade from a pre-language-pair build.
    func testInitDefaultsTargetLanguageToGerman() async throws {
        let state = AddableListReducer.State(
            data: [],
            key: key,
            phraseToItemState: { $0 },
            phraseToSearchableString: { "\($0.id) \($0.translation)" }
        )
        XCTAssertEqual(state.targetLanguage, .german)
    }

    func testAddNewTappedSeedsNewWithStateTargetLanguage() async throws {
        let state = makeState(targetLanguage: .french)
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addNewTapped)

        XCTAssertEqual(store.state.new?.targetLanguage, .french)
    }

    func testEditPhraseSeedsEditWithStateTargetLanguage() async throws {
        let phrase = Phrase(id: "hola", translation: "hello", createdAt: Date())
        let state = makeState(data: [phrase], targetLanguage: .spanish)
        let store = TestStore(initialState: state) { AddableListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.editPhrase(id: "hola"))

        XCTAssertEqual(store.state.edit?.targetLanguage, .spanish)
        XCTAssertEqual(store.state.edit?.text, "hola")
        XCTAssertEqual(store.state.edit?.translation, "hello")
    }

    // MARK: - Data preservation across upgrade

    // Pin the persisted-format guarantee: phrases written under a key by a
    // pre-language-pair build must round-trip through `loadData` after the
    // upgrade. The on-disk format for `[Phrase]` is unchanged — Phrase itself
    // gained no fields — and `AddableListReducer.State.init` defaulting
    // `targetLanguage` to .german preserves the legacy German↔English UX.
    func testLegacyPhrasesAtKeyAreLoadedAfterUpgrade() async throws {
        let legacy = [
            Phrase(id: "Hund", translation: "dog", createdAt: Date(timeIntervalSinceNow: -10)),
            Phrase(id: "Katze", translation: "cat", createdAt: Date(timeIntervalSinceNow: -5)),
        ]
        // Write directly with the persistence helper, simulating data left
        // behind by an older app version.
        save(legacy, for: key)

        // Upgrade-simulating call: existing call sites that used the old
        // 2-arg init form. They still compile because targetLanguage defaults.
        let state = AddableListReducer.State(
            data: loadData(key),
            key: key,
            phraseToItemState: { $0 },
            phraseToSearchableString: { "\($0.id) \($0.translation)" }
        )

        XCTAssertEqual(state.allPhrases.count, 2)
        XCTAssertNotNil(state.allPhrases[id: "Hund"])
        XCTAssertNotNil(state.allPhrases[id: "Katze"])
        XCTAssertEqual(state.targetLanguage, .german)
    }

    func testLegacyDefaultPhrasesKeyStillLoads() async throws {
        // The pre-refactor app stored everything under the literal key
        // "phrases". Confirm a default-key load still works.
        let legacy = [Phrase(id: "alt", translation: "old", createdAt: Date())]
        save(legacy, for: "phrases")

        let loaded = loadData()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, "alt")
    }
}
