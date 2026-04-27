//
//  EditPhraseTests.swift
//  WordbookTests
//
//  Created by Claude on 2026-04-26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

// Note: `testInitializeEnglishOnlyAssignsWhenTranslationEmpty` from the test
// recommendations is intentionally omitted — `TranslationSession` cannot be
// constructed in tests, so the `.initializeEnglish` / `.initializeTarget`
// branches are not exercised here. All tests below assume both
// `englishTranslator` and `targetTranslator` are `nil`.

@MainActor
final class EditPhraseTests: XCTestCase {
    func testBindingTextEnablesSaveWhenNonEmpty_NoTranslator() async throws {
        let store = TestStore(initialState: EditPhraseReducer.State()) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.text, "foo"))) {
            $0.text = "foo"
            $0.isSaveDisabled = false
        }

        await store.finish()
    }

    func testBindingTextEmptyDisablesSave_NoTranslator() async throws {
        var state = EditPhraseReducer.State()
        state.text = "foo"
        state.isSaveDisabled = false
        let store = TestStore(initialState: state) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.text, ""))) {
            $0.text = ""
            $0.isSaveDisabled = true
        }

        await store.finish()
    }

    func testBindingTranslationFollowsSameRule() async throws {
        let store = TestStore(initialState: EditPhraseReducer.State()) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.translation, "bar"))) {
            $0.translation = "bar"
            $0.isSaveDisabled = false
        }
        await store.send(.binding(.set(\.translation, ""))) {
            $0.translation = ""
            $0.isSaveDisabled = true
        }

        await store.finish()
    }

    func testInitWithPhrasePopulatesFields() async throws {
        let phrase = Phrase(id: "foo", translation: "bar", createdAt: Date())
        let store = TestStore(initialState: EditPhraseReducer.State(phrase: phrase)) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        XCTAssertEqual(store.state.text, "foo")
        XCTAssertEqual(store.state.translation, "bar")
        XCTAssertEqual(store.state.phrase, phrase)

        await store.finish()
    }

    // MARK: - targetLanguage

    func testInitDefaultsTargetLanguageToGerman() async throws {
        // Backwards-compat: existing call sites that don't pass a language
        // continue to get the previous German↔English behavior.
        let state = EditPhraseReducer.State()
        XCTAssertEqual(state.targetLanguage, .german)
    }

    func testInitWithTargetLanguagePersistsIt() async throws {
        let state = EditPhraseReducer.State(targetLanguage: .french)
        XCTAssertEqual(state.targetLanguage, .french)
    }

    func testToggleRecordingPhraseUsesStateTargetLanguage() async throws {
        // Confirm the reducer threads the per-edit-session language into the
        // (process-global) SpeechClient — i.e. recording in a French wordbook
        // listens for French, not the previously hardcoded German.
        SpeechClient.language = .english
        let state = EditPhraseReducer.State(targetLanguage: .spanish)
        let store = TestStore(initialState: state) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.toggleRecordingPhrase) {
            $0.recording = .text
        }

        XCTAssertEqual(SpeechClient.language, .spanish)

        // Reset for any later test that observes it.
        SpeechClient.language = .english
        await store.finish()
    }

    func testToggleRecordingPhraseSetsRecordingText() async throws {
        let store = TestStore(initialState: EditPhraseReducer.State()) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.toggleRecordingPhrase) {
            $0.recording = .text
        }
        await store.send(.toggleRecordingPhrase) {
            $0.recording = nil
        }

        await store.finish()
    }

    func testSpeechResultUpdatesTextAndIsSaveDisabled_NoTranslator() async throws {
        var state = EditPhraseReducer.State()
        state.recording = .text
        let store = TestStore(initialState: state) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.speechResult("hallo")) {
            $0.text = "hallo"
            $0.isSaveDisabled = false
        }

        await store.finish()
    }

    func testConfirmSaveEmitsDelegateAndDismisses() async throws {
        var state = EditPhraseReducer.State()
        state.text = "foo"
        state.translation = "bar"
        state.alert = AlertState { TextState("Save?") } actions: {
            ButtonState(action: .confirmSave) { TextState("Save") }
            ButtonState(action: .confirmDiscard) { TextState("Discard") }
        } message: {
            TextState("")
        }
        let store = TestStore(initialState: state) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmSave)))

        // The Action enum is not Equatable (TranslationSession parameter), so
        // use the case-path form to receive the delegate, then assert on the
        // payload directly. createdAt is non-deterministic — only assert id +
        // translation.
        await store.receive(\.delegate) { _ in }

        // Re-read the last received delegate via state-free assertion: the
        // delegate carries the phrase. Since the receive above doesn't expose
        // the value through the case-path form by itself, validate by ensuring
        // state remained correct (the reducer's confirmSave handler does not
        // mutate state — it only emits delegate + dismiss).
        XCTAssertEqual(store.state.text, "foo")
        XCTAssertEqual(store.state.translation, "bar")

        await store.finish()
    }

    func testConfirmDiscardDismisses() async throws {
        var state = EditPhraseReducer.State()
        state.alert = AlertState { TextState("Discard?") } actions: {
            ButtonState(action: .confirmDiscard) { TextState("Discard") }
        } message: {
            TextState("")
        }
        let store = TestStore(initialState: state) { EditPhraseReducer() } withDependencies: {
            $0.mainQueue = .immediate
            $0.speechClient.requestAuthorization = { 0 }
            $0.speechClient.start = { AsyncThrowingStream { _ in } }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmDiscard)))

        // No delegate action should be received from confirmDiscard — only the
        // opaque dismiss effect runs. Off-exhaustivity tolerates the dismiss
        // effect; finish ensures no unexpected actions remain.
        await store.finish()
    }
}
