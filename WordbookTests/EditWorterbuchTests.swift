//
//  EditWorterbuchTests.swift
//  WordbookTests
//
//  Created by Claude on 4/26/26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class EditWorterbuchTests: XCTestCase {
    func testBindingMutatesWorterbuchName() async throws {
        let initialState = EditWorterbuchReducer.State(
            id: UUID(),
            worterbuch: Worterbuch(id: UUID(), name: "old", key: "k")
        )
        let store = TestStore(initialState: initialState) { EditWorterbuchReducer() } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.worterbuch.name, "new"))) {
            $0.worterbuch.name = "new"
        }

        await store.finish()
    }

    func testBindingMutatesTargetLanguage() async throws {
        // The language Picker in EditWorterbuchView writes through this binding;
        // confirm the reducer accepts and persists the new value.
        let initialState = EditWorterbuchReducer.State(
            id: UUID(),
            worterbuch: Worterbuch(id: UUID(), name: "n", key: "k", targetLanguage: .german)
        )
        let store = TestStore(initialState: initialState) { EditWorterbuchReducer() } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.binding(.set(\.worterbuch.targetLanguage, .italian))) {
            $0.worterbuch.targetLanguage = .italian
        }

        await store.finish()
    }

    func testInitDefaultsTargetLanguageToGerman() async throws {
        // The Worterbuch convenience init defaults to .german so existing
        // call sites that don't specify a language continue to compile and
        // get the previous behavior.
        let buch = Worterbuch(name: "n", key: "k")
        XCTAssertEqual(buch.targetLanguage, .german)
    }
}
