//
//  PhrasesTests.swift
//  WordbookAW Watch AppTests
//
//  Tests for the watch PhrasesReducer (WordbookAW Watch App/PhrasesReducer.swift),
//  which composes the shared PhraseListReducer (Wordbook/Old/PhraseListReducer.swift)
//  and the watch AddPhraseReducer (WordbookAW Watch App/AddPhraseReducer.swift).
//
//  Notes:
//  - PhraseListReducer.State.init defaults `data` to `loadData()` which reads
//    UserDefaults at key "phrases". setUp/tearDown clear that key, and we
//    pass `data: []` (or seed phrases explicitly) to avoid leakage.
//  - PhraseListReducer touches WatchConnectivityClient.session.sendMessage(...)
//    on .onAppear/.dataNeedsReload/.addPhrase. This is a no-op on the
//    simulator and is not asserted on here.
//  - The watch AddPhraseReducer uses @BindingState, not @ObservableState, so
//    binding writes use `\.$text` (the projected-value keypath).
//  - PhrasesReducer.savePhrase builds a Phrase with `Date()`; createdAt is
//    non-deterministic, so we assert only on `id` / `translation`.
//

import XCTest
import ComposableArchitecture
@testable import WordbookAW_Watch_App

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

    func testAddPhrasePresents() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.addPhrase) {
            $0.addState = AddPhraseReducer.State()
        }

        await store.finish()
    }

    func testCancelPhraseClears() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        state.addState = AddPhraseReducer.State()
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.cancelPhrase) {
            $0.addState = nil
        }

        await store.finish()
    }

    func testSavePhraseAddsToList() async throws {
        var state = PhrasesReducer.State()
        state.phrases = PhraseListReducer.State(data: [])
        state.addState = AddPhraseReducer.State()
        let store = TestStore(initialState: state) { PhrasesReducer() } withDependencies: {
            $0.watchConnectivityClient = WatchConnectivityClient(didActivate: {})
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        // Drive the watch AddPhrase child's text via the projected-value keypath
        // (watch reducer uses @BindingState, so we need the `$` prefix).
        await store.send(.add(.presented(.binding(.set(\.$text, "foo"))))) {
            $0.addState?.text = "foo"
        }

        await store.send(.savePhrase) {
            $0.addState = nil
        }

        // PhrasesReducer fires `.list(.addPhrase(<phrase>))` with createdAt = Date().
        // Watch PhrasesReducer is not @Reducer-macro'd so case-path receive is unavailable;
        // and createdAt is non-deterministic, so we drain effects and inspect state.
        await store.skipReceivedActions(strict: false)

        XCTAssertEqual(store.state.phrases.data.count, 1)
        XCTAssertEqual(store.state.phrases.data.first?.id, "foo")
        XCTAssertNil(store.state.addState)

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
}
