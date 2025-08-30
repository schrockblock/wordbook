//
//  ForgotPasswordTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import FunNetCore
import FunNetTCA
import ComposableArchitecture
@testable import Template

@MainActor
final class ForgotPasswordTests: XCTestCase {
    func testForgotPasswordEnabled() async throws {
        var state = ForgotPasswordReducer.State()
        state.forgotPasswordCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { ForgotPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.binding(.set(\.username, "elliot"))) {
            $0.username = "elliot"
            $0.isButtonEnabled = true
        }
        
        await store.finish()
    }
    
    func testReset() async throws {
        var state = ForgotPasswordReducer.State(username: "elliot")
        state.forgotPasswordCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { ForgotPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: "elliot"))
        await store.send(.didTapReset) {
            $0.forgotPasswordCallState.endpoint.postData = authData
        }
        
        await store.receive(.forgotPasswordCall(.fire)) {
            $0.forgotPasswordCallState.isInProgress = true
        }
        
        await store.receive(.forgotPasswordCall(.delegate(.responseData(mockUser.data(using: .utf8)!)))) {
            $0.isButtonEnabled = true
            $0.forgotPasswordCallState.isInProgress = false
        }
        await store.receive(.delegate(.didReset))
        
        await store.finish()
    }
    
    func testForgotPasswordError() async throws {
        var state = ForgotPasswordReducer.State()
        state.forgotPasswordCallState.firingFunc = NetCallReducer.mockFire(with: nil, error: NSError(domain: "Server", code: 401), delayMillis: 10)
        let store = TestStore(initialState: state) { ForgotPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: ""))
        await store.send(.didTapReset) {
            $0.forgotPasswordCallState.endpoint.postData = authData
        }
        
        await store.receive(.forgotPasswordCall(.fire)) {
            $0.forgotPasswordCallState.isInProgress = true
        }
        
        await store.receive(.forgotPasswordCall(.delegate(.error(NSError(domain: "Server", code: 401))))) {
            $0.isButtonEnabled = true
            $0.forgotPasswordCallState.isInProgress = false
            $0.alert = AlertState { TextState("Error: 401") } actions: {} message: {
                TextState("Unauthorized")
            }
        }
        
        await store.finish()
    }

}
