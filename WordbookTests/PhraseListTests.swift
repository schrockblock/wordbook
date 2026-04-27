//
//  PhraseListTests.swift
//  WordbookTests
//
//  Created by Claude on 2026-04-26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class PhraseListTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "phrases")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "phrases")
        super.tearDown()
    }

    func testAddPhraseInsertsAtFrontAndPersists() async throws {
        let state = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        let phrase = Phrase(id: "foo", translation: "bar", createdAt: Date())
        await store.send(.addPhrase(phrase))

        XCTAssertEqual(store.state.data.count, 1)
        XCTAssertEqual(store.state.data[0].id, "foo")
        XCTAssertEqual(store.state.list.first?.id, "foo")

        // Confirm persistence to default "phrases" key.
        let savedData = UserDefaults.standard.data(forKey: "phrases")
        XCTAssertNotNil(savedData)
        if let savedData {
            let decoded = try JSONDecoder().decode([Phrase].self, from: savedData)
            XCTAssertEqual(decoded.first?.id, "foo")
        }
    }

    func testDataNeedsReloadReadsFromUserDefaults() async throws {
        // Pre-populate the default "phrases" UserDefaults entry.
        let preloaded = [
            Phrase(id: "one", translation: "eins", createdAt: Date(timeIntervalSinceNow: -2)),
            Phrase(id: "two", translation: "zwei", createdAt: Date(timeIntervalSinceNow: -1)),
        ]
        save(preloaded)

        let state = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.dataNeedsReload)

        XCTAssertEqual(store.state.data.count, 2)
        let ids = Set(store.state.data.map(\.id))
        XCTAssertEqual(ids, Set(["one", "two"]))
    }

    func testSortByAlphabet() async throws {
        let phrases = [
            Phrase(id: "banana", translation: "Banane", createdAt: Date(timeIntervalSinceNow: -1)),
            Phrase(id: "apple", translation: "Apfel", createdAt: Date()),
        ]
        let state = PhraseListReducer.State(data: phrases)
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.sortByAlphabet)

        XCTAssertEqual(store.state.sortScheme, .alphabet)
        XCTAssertEqual(store.state.list.map(\.id), ["apple", "banana"])
    }

    func testSortByRecent() async throws {
        let older = Phrase(id: "older", translation: "alt", createdAt: Date(timeIntervalSinceNow: -100))
        let newer = Phrase(id: "newer", translation: "neu", createdAt: Date())
        let state = PhraseListReducer.State(data: [older, newer])
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Force a non-recent scheme first to verify the action flips it back.
        await store.send(.sortByAlphabet)
        XCTAssertEqual(store.state.sortScheme, .alphabet)

        await store.send(.sortByRecent)

        XCTAssertEqual(store.state.sortScheme, .recent)
        XCTAssertEqual(store.state.list.map(\.id), ["newer", "older"])
    }

    func testRemovePhraseIsCurrentlyNoop() async throws {
        let phrase = Phrase(id: "foo", translation: "bar", createdAt: Date())
        let state = PhraseListReducer.State(data: [phrase])
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.removePhrase(id: "foo"))

        // Documents the commented-out implementation: state is unchanged.
        XCTAssertEqual(store.state.data.count, 1)
        XCTAssertEqual(store.state.data.first?.id, "foo")
        XCTAssertEqual(store.state.list.count, 1)
    }

    func testShuffleIsCurrentlyNoop() async throws {
        let phrases = [
            Phrase(id: "a", translation: "A", createdAt: Date(timeIntervalSinceNow: -1)),
            Phrase(id: "b", translation: "B", createdAt: Date()),
        ]
        let state = PhraseListReducer.State(data: phrases)
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        let listBefore = store.state.list.map(\.id)
        await store.send(.shuffle)
        let listAfter = store.state.list.map(\.id)

        XCTAssertEqual(listBefore, listAfter)
        XCTAssertEqual(store.state.data.count, 2)
    }

    func testOnAppearIsLongRunningEffect() async throws {
        let state = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhraseListReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        let dataBefore = store.state.data
        let listBefore = store.state.list
        let schemeBefore = store.state.sortScheme

        // `.onAppear` kicks off a long-running effect (watchClient.start() stream).
        // We do NOT await store.finish() because the stream never completes.
        // Just confirm no synchronous state mutation.
        await store.send(.onAppear)

        XCTAssertEqual(store.state.data, dataBefore)
        XCTAssertEqual(store.state.list, listBefore)
        XCTAssertEqual(store.state.sortScheme, schemeBefore)
    }
}
