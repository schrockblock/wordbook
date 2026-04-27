//
//  PhraseTests.swift
//  WordbookTests
//
//  Created by Elliot Schrock on 4/26/26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class PhraseTests: XCTestCase {
    func testDidTapEmitsDelegate() async throws {
        let phrase = Phrase(id: "hund", translation: "dog", createdAt: Date())
        let store = TestStore(initialState: phrase) { PhraseReducer() }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.didTap)
        await store.receive(.delegate(.didTap(phrase)))

        await store.finish()
    }
}
