//
//  LandingTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class LandingTests: XCTestCase {
    func testLogin() async throws {
        let store = TestStore(initialState: LandingReducer.State(), reducer: { LandingReducer() })
        
        await store.send(.didTapLogin) {
            $0.login = LoginReducer.State()
        }
    }
    
    func testSignUp() async throws {
        let store = TestStore(initialState: LandingReducer.State(), reducer: { LandingReducer() })

        await store.send(.didTapSignUp) {
            $0.signUp = SignUpReducer.State()
        }
    }

    func testTapLoginThenChildLoginAdvanceFiresThrough() async throws {
        let store = TestStore(initialState: LandingReducer.State(), reducer: { LandingReducer() })
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.didTapLogin) {
            $0.login = LoginReducer.State()
        }

        // LandingReducer is a pass-through for the auth delegate; it does not
        // mutate state.login itself — the parent (SplashReducer) handles dismissal.
        await store.send(.login(.presented(.delegate(.advanceAuthed))))

        XCTAssertNotNil(store.state.login)
    }

    func testTapSignUpClearsNoOtherState() async throws {
        let store = TestStore(initialState: LandingReducer.State(), reducer: { LandingReducer() })

        await store.send(.didTapLogin) {
            $0.login = LoginReducer.State()
        }

        // LandingReducer does NOT auto-clear when opening the other sheet.
        await store.send(.didTapSignUp) {
            $0.signUp = SignUpReducer.State()
        }

        XCTAssertNotNil(store.state.login)
        XCTAssertNotNil(store.state.signUp)
    }
}
