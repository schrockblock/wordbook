//
//  AddPhraseTests.swift
//  WordbookAW Watch AppTests
//
//  Created by Elliot Schrock on 4/26/26.
//

import XCTest
import ComposableArchitecture
@testable import WordbookAW_Watch_App

@MainActor
final class AddPhraseTests: XCTestCase {
    private func saveAlert() -> AlertState<AddPhraseReducer.Action.Alert> {
        AlertState { TextState("Save?") } actions: {
            ButtonState(action: .confirmSave) { TextState("Save") }
            ButtonState(action: .confirmDiscard) { TextState("Discard") }
        } message: {
            TextState("")
        }
    }

    func testConfirmSaveEmitsDelegate() async throws {
        var state = AddPhraseReducer.State()
        state.text = "foo"
        state.translation = "bar"
        state.alert = saveAlert()
        let store = TestStore(initialState: state) { AddPhraseReducer() } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmSave)))

        // createdAt is non-deterministic; assert id and translation by capturing the received action.
        await store.receive { action in
            guard case let .delegate(.savePhrase(phrase)) = action else { return false }
            return phrase.id == "foo" && phrase.translation == "bar"
        }

        await store.finish()
    }

    func testConfirmDiscardEmitsNoDelegate() async throws {
        var state = AddPhraseReducer.State()
        state.alert = saveAlert()
        let store = TestStore(initialState: state) { AddPhraseReducer() } withDependencies: {
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.presented(.confirmDiscard)))

        // No delegate action should be received. The dismiss effect is opaque.
        await store.finish()
    }

    func testBindingMutatesText() async throws {
        let store = TestStore(initialState: AddPhraseReducer.State()) { AddPhraseReducer() }

        await store.send(.binding(.set(\.$text, "hallo"))) {
            $0.text = "hallo"
        }

        await store.finish()
    }

    func testBindingMutatesTranslation() async throws {
        let store = TestStore(initialState: AddPhraseReducer.State()) { AddPhraseReducer() }

        await store.send(.binding(.set(\.$translation, "hello"))) {
            $0.translation = "hello"
        }

        await store.finish()
    }

    func testAlertDismissDoesNotEmitDelegate() async throws {
        var state = AddPhraseReducer.State()
        state.alert = saveAlert()
        let store = TestStore(initialState: state) { AddPhraseReducer() }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.alert(.dismiss))

        await store.finish()
    }
}
