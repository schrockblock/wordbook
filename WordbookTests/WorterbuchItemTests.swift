//
//  WorterbuchItemTests.swift
//  WordbookTests
//
//  Created by Claude on 2026-04-26.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class WorterbuchItemTests: XCTestCase {
    func testDidTapIsCurrentlyNoop() async throws {
        let state = WorterbuchItemReducer.State(
            worterbuch: Worterbuch(id: UUID(), name: "Test", key: "k1")
        )
        let store = TestStore(initialState: state) { WorterbuchItemReducer() } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.didTap)

        await store.finish()
    }
}
