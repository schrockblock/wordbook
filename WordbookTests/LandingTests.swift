//
//  LandingTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import ComposableArchitecture
@testable import Template

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
}
