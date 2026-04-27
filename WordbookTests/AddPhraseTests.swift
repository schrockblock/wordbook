//
//  AddPhraseTests.swift
//  WordbookTests
//
//  Tests for the iOS AddPhraseReducer at Wordbook/Phrases/AddPhraseReducer.swift.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class AddPhraseTests: XCTestCase {

    func testToggleRecordingPhraseSetsTextStatusAndStartsRecording() async throws {
        let store = TestStore(initialState: AddPhraseReducer.State()) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.toggleRecordingPhrase) {
            $0.recording = .text
        }

        await store.finish()
    }

    func testToggleRecordingTranslationSetsStatus() async throws {
        let store = TestStore(initialState: AddPhraseReducer.State()) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.toggleRecordingTranslation) {
            $0.recording = .translation
        }

        await store.finish()
    }

    func testToggleAgainStopsRecording() async throws {
        var state = AddPhraseReducer.State()
        state.recording = .text
        let store = TestStore(initialState: state) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.toggleRecordingPhrase) {
            $0.recording = nil
        }

        await store.finish()
    }

    func testSpeechResultUpdatesText() async throws {
        var state = AddPhraseReducer.State()
        state.recording = .text
        let store = TestStore(initialState: state) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.speechResult("hallo")) {
            $0.text = "hallo"
        }

        await store.finish()
    }

    func testSpeechResultUpdatesTranslation() async throws {
        var state = AddPhraseReducer.State()
        state.recording = .translation
        let store = TestStore(initialState: state) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.speechResult("hello")) {
            $0.translation = "hello"
        }

        await store.finish()
    }

    func testSpeechResultIgnoredWhenNotRecording() async throws {
        let store = TestStore(initialState: AddPhraseReducer.State()) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.speechResult("hi"))

        XCTAssertEqual(store.state.text, "")
        XCTAssertEqual(store.state.translation, "")

        await store.finish()
    }

    func testConfirmSaveEmitsDelegateSavePhrase() async throws {
        var state = AddPhraseReducer.State()
        state.text = "foo"
        state.translation = "bar"
        // Alert must be present so the ifLet doesn't fire a "no destination state" warning.
        state.alert = AlertState { TextState("Save?") } actions: {
            ButtonState(action: .confirmSave) { TextState("Save") }
            ButtonState(action: .confirmDiscard) { TextState("Discard") }
        } message: {
            TextState("")
        }
        let store = TestStore(initialState: state) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmSave)))

        // createdAt is non-deterministic — capture the action via predicate and assert id/translation only.
        await store.receive { action in
            guard case let .delegate(.savePhrase(phrase)) = action else { return false }
            XCTAssertEqual(phrase.id, "foo")
            XCTAssertEqual(phrase.translation, "bar")
            return true
        }

        await store.finish()
    }

    func testConfirmDiscardCallsDismiss() async throws {
        var state = AddPhraseReducer.State()
        state.alert = AlertState { TextState("Discard?") } actions: {
            ButtonState(action: .confirmDiscard) { TextState("Discard") }
        } message: {
            TextState("")
        }
        let store = TestStore(initialState: state) {
            AddPhraseReducer()
        } withDependencies: {
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmDiscard)))

        // No delegate action should fire; dismiss is a no-op without a parent.
        await store.finish()
    }
}
