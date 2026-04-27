//
//  WorterbuchListTests.swift
//  WordbookTests
//
//  Created by Claude on 4/26/26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class WorterbuchListTests: XCTestCase {

    // Track the unique UserDefaults key used by each test so we can clear it.
    private var testKeys: [String] = []

    private func makeUniqueKey() -> String {
        let key = "buch_\(UUID().uuidString)"
        testKeys.append(key)
        return key
    }

    override func tearDown() {
        for key in testKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        testKeys.removeAll()
        // saveNew writes to the wordbooks index; clear it between tests.
        UserDefaults.standard.removeObject(forKey: worterbuchsKey)
        super.tearDown()
    }

    // MARK: Helpers

    private func makeState(
        allWorterbuchs: IdentifiedArrayOf<Worterbuch> = .init(),
        localFilter: String = ""
    ) -> WorterbuchListReducer.State {
        WorterbuchListReducer.State(
            allWorterbuchs: allWorterbuchs,
            localFilter: localFilter,
            worterbuchToItemState: { WorterbuchItemReducer.State(worterbuch: $0) },
            worterbuchToSearchableString: { $0.name }
        )
    }

    // MARK: Tests

    func testAddNewTappedPresentsNewWithDefaultLanguage() async throws {
        let state = makeState()
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addNewTapped)

        XCTAssertNotNil(store.state.new)
        XCTAssertEqual(store.state.new?.worterbuch.name, "")
        XCTAssertEqual(store.state.new?.worterbuch.targetLanguage, .german)
        // Each new wordbook gets a unique storage key derived from its UUID
        // so it doesn't collide with the legacy default "phrases" bucket.
        XCTAssertNotEqual(store.state.new?.worterbuch.key, "phrases")
        XCTAssertTrue(store.state.new?.worterbuch.key.hasPrefix("phrases_") == true)

        await store.finish()
    }

    func testSaveNewAppendsToAllWorterbuchsAndDismisses() async throws {
        // Start from a guaranteed-empty index so the seed-from-legacy path
        // doesn't preload a Default wordbook into our state.
        UserDefaults.standard.removeObject(forKey: worterbuchsKey)
        UserDefaults.standard.removeObject(forKey: "phrases")

        let state = makeState()
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addNewTapped)
        // Mutate the in-progress wordbook via the child binding before saving.
        await store.send(.new(.presented(.binding(.set(\.worterbuch.name, "Tiere")))))
        await store.send(.new(.presented(.binding(.set(\.worterbuch.targetLanguage, .french)))))

        await store.send(.saveNew)

        XCTAssertEqual(store.state.allWorterbuchs.count, 1)
        XCTAssertEqual(store.state.allWorterbuchs.first?.name, "Tiere")
        XCTAssertEqual(store.state.allWorterbuchs.first?.targetLanguage, .french)
        XCTAssertNil(store.state.new)

        // Persistence: saveNew must write through to UserDefaults so the
        // wordbook survives an app relaunch.
        let persisted = loadWorterbuchs()
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.first?.name, "Tiere")
        XCTAssertEqual(persisted.first?.targetLanguage, .french)

        await store.finish()
    }

    func testCancelClearsNew() async throws {
        let state = makeState()
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addNewTapped)
        XCTAssertNotNil(store.state.new)

        await store.send(.cancel)

        XCTAssertNil(store.state.new)
        XCTAssertEqual(store.state.allWorterbuchs.count, 0)

        await store.finish()
    }

    func testWorterbuchTapPresentsDetails() async throws {
        let key = makeUniqueKey()

        // Pre-populate UserDefaults at the buch's key with phrases so that
        // `loadData(buch.key)` returns them when the tap fires.
        let phrases = [
            Phrase(id: "Hund", translation: "dog", createdAt: Date()),
            Phrase(id: "Katze", translation: "cat", createdAt: Date())
        ]
        save(phrases, for: key)

        let buch = Worterbuch(id: UUID(), name: "Tiere", key: key)
        let state = makeState(allWorterbuchs: IdentifiedArrayOf(uniqueElements: [buch]))
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.worterbuch(buch.id, .didTap))

        XCTAssertNotNil(store.state.details)
        XCTAssertEqual(store.state.details?.key, key)
        XCTAssertEqual(store.state.details?.targetLanguage, .german)
        // The two pre-populated phrases should have been loaded into the
        // details state (uniqueness is by `Phrase.id`).
        XCTAssertEqual(store.state.details?.allPhrases.count, 2)
        XCTAssertEqual(Set(store.state.details?.allPhrases.map(\.id) ?? []), Set(["Hund", "Katze"]))

        await store.finish()
    }

    // Regression: the List in WorterbuchListView dispatches taps using
    // `worterbuchStore.id` — i.e. WorterbuchItemReducer.State.id, not the
    // Worterbuch's id directly. If those two ids ever drift apart, the tap
    // handler's `state.allWorterbuchs[id: id]` lookup silently fails and
    // navigation breaks. This test pins the routing path the UI actually uses.
    func testTapViaDisplayedItemStateRoutesToDetails() async throws {
        let key = makeUniqueKey()
        let buch = Worterbuch(id: UUID(), name: "Tiere", key: key, targetLanguage: .german)
        let state = makeState(allWorterbuchs: IdentifiedArrayOf(uniqueElements: [buch]))
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Drive through the item store's id, the way the View does.
        let itemId = store.state.displayedWorterbuchStates.first!.id
        await store.send(.worterbuch(itemId, .didTap))

        XCTAssertNotNil(store.state.details)
        XCTAssertEqual(store.state.details?.key, key)
    }

    func testWorterbuchTapPropagatesNonDefaultLanguageToDetails() async throws {
        let key = makeUniqueKey()
        let buch = Worterbuch(id: UUID(), name: "Cuisine", key: key, targetLanguage: .french)
        let state = makeState(allWorterbuchs: IdentifiedArrayOf(uniqueElements: [buch]))
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.worterbuch(buch.id, .didTap))

        XCTAssertEqual(store.state.details?.targetLanguage, .french)
    }

    func testWorterbuchTapMissingIdIsNoop() async throws {
        let state = makeState()
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.worterbuch(UUID(), .didTap))

        XCTAssertNil(store.state.details)

        await store.finish()
    }

    func testDidChangeScenePhaseIsNoop() async throws {
        let buch = Worterbuch(id: UUID(), name: "Tiere", key: "ignored")
        let state = makeState(allWorterbuchs: IdentifiedArrayOf(uniqueElements: [buch]))
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.didChangeScenePhase)

        // Documents the placeholder no-op branch.
        XCTAssertEqual(store.state.allWorterbuchs, IdentifiedArrayOf(uniqueElements: [buch]))
        XCTAssertNil(store.state.new)
        XCTAssertNil(store.state.edit)
        XCTAssertNil(store.state.details)

        await store.finish()
    }

    func testLocalFilterBindingDoesNotMutateAllWorterbuchs() async throws {
        let hund = Worterbuch(id: UUID(), name: "Hund", key: "k_hund")
        let katze = Worterbuch(id: UUID(), name: "Katze", key: "k_katze")
        let state = makeState(
            allWorterbuchs: IdentifiedArrayOf(uniqueElements: [hund, katze])
        )
        let store = TestStore(initialState: state) { WorterbuchListReducer() } withDependencies: {
            $0.uuid = .incrementing
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Sanity: with no filter, both Worterbuchs are displayed.
        XCTAssertEqual(store.state.displayedWorterbuchStates.count, 2)

        await store.send(.binding(.set(\.localFilter, "Hun")))

        // `allWorterbuchs` is the source of truth and must be unchanged.
        XCTAssertEqual(
            store.state.allWorterbuchs,
            IdentifiedArrayOf(uniqueElements: [hund, katze])
        )

        // `displayedWorterbuchStates` is computed; reading it should yield
        // only the matching Worterbuch.
        let displayed = store.state.displayedWorterbuchStates
        XCTAssertEqual(displayed.count, 1)
        XCTAssertEqual(displayed.first?.worterbuch.name, "Hund")

        await store.finish()
    }
}
