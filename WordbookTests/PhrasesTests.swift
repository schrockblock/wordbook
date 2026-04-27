//
//  PhrasesTests.swift
//  WordbookTests
//
//  Tests for the iOS PhrasesReducer (Wordbook/PhrasesReducer.swift),
//  which composes PhraseListReducer (Wordbook/Old/PhraseListReducer.swift)
//  and EditPhraseReducer (Wordbook/Phrases/EditPhraseReducer.swift).
//
//  Notes:
//  - PhraseListReducer.State.init defaults `data` to `loadData()` which reads
//    UserDefaults at key "phrases". setUp/tearDown clear that key, and we
//    pass `data: []` (or seed the state explicitly) to avoid leakage.
//  - PhraseListReducer touches WatchConnectivityClient.session.sendMessage(...)
//    on .onAppear/.dataNeedsReload/.addPhrase. This is a no-op on the
//    simulator and is not asserted on here.
//  - PhrasesReducer.Action is not Equatable, so we receive via case-path
//    (`store.receive(\.list)`).
//  - PhrasesReducer.savePhrase builds a Phrase with `Date()`; createdAt is
//    non-deterministic, so we assert only on `id` / `translation`.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class PhrasesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "phrases")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "phrases")
        super.tearDown()
    }

    func testAddPhrasePresentsEditState() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addPhrase) {
            $0.addState = EditPhraseReducer.State()
        }

        await store.finish()
    }

    func testCancelPhraseClearsEditState() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        state.addState = EditPhraseReducer.State()
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.cancelPhrase) {
            $0.addState = nil
        }

        await store.finish()
    }

    func testSavePhraseEmitsAddPhraseToList() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        state.addState = EditPhraseReducer.State()
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Drive the EditPhrase child's text/translation via presentation bindings.
        await store.send(.add(.presented(.binding(.set(\.text, "foo"))))) {
            $0.addState?.text = "foo"
        }
        await store.send(.add(.presented(.binding(.set(\.translation, "bar"))))) {
            $0.addState?.translation = "bar"
        }

        await store.send(.savePhrase) {
            $0.addState = nil
        }

        // PhrasesReducer sends `.list(.addPhrase(phrase))` with createdAt = Date().
        // Action is not Equatable and reducer is not @Reducer-macro'd, so case-path receive is unavailable.
        // Drain in-flight effects, then assert resulting state.
        await store.skipReceivedActions(strict: false)

        XCTAssertEqual(store.state.phrases.data.count, 1)
        XCTAssertEqual(store.state.phrases.data.first?.id, "foo")
        XCTAssertEqual(store.state.phrases.data.first?.translation, "bar")

        await store.finish()
    }

    func testOnAppearIsNoop() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // PhrasesReducer's own `.onAppear` returns `.none` (no state change).
        // The inner PhraseListReducer's `.onAppear` is a separate action and
        // is not forwarded here. Asserting parent `.onAppear` is a true no-op.
        await store.send(.onAppear)

        XCTAssertNil(store.state.addState)
        XCTAssertEqual(store.state.phrases.data.count, 0)

        await store.finish()
    }

    func testListSubreducerForwarding() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // `.shuffle` is a no-op in PhraseListReducer (the body has `case .shuffle: break`)
        // but routing through Scope still mutates nothing — documents the wiring.
        await store.send(.list(.shuffle))

        XCTAssertEqual(store.state.phrases.data.count, 0)
        XCTAssertEqual(store.state.phrases.list.count, 0)

        await store.finish()
    }
}
