//
//  ResetPasswordTests.swift
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
final class ResetPasswordTests: XCTestCase {
    func testResetEnabled() async throws {
        var state = ResetPasswordReducer.State()
        state.resetPasswordCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { ResetPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.binding(.set(\.password, "password"))) {
            $0.password = "password"
        }
        await store.send(.binding(.set(\.password, ""))) {
            $0.password = ""
        }
        await store.send(.binding(.set(\.password, "password"))) {
            $0.password = "password"
        }
        await store.send(.binding(.set(\.confirmPassword, "password"))) {
            $0.confirmPassword = "password"
            $0.isButtonEnabled = true
        }
        
        await store.finish()
    }
    
    func testReset() async throws {
        var state = ResetPasswordReducer.State()
        state.resetPasswordCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { ResetPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.binding(.set(\.password, "password"))) {
            $0.password = "password"
        }
        await store.send(.binding(.set(\.confirmPassword, "password"))) {
            $0.confirmPassword = "password"
            $0.isButtonEnabled = true
        }
        
        let authData = try? JSONEncoder().encode(User(password: "password"))
        await store.send(.didTapReset) {
            $0.resetPasswordCallState.endpoint.postData = authData
            $0.isButtonEnabled = false
        }
        
        await store.receive(.resetPasswordCall(.fire)) {
            $0.resetPasswordCallState.isInProgress = true
        }
        
        await store.receive(.resetPasswordCall(.delegate(.responseData(mockUser.data(using: .utf8)!)))) {
            $0.resetPasswordCallState.isInProgress = false
            $0.isButtonEnabled = true
        }
        await store.receive(.delegate(.didReset))
        
        await store.finish()
    }
    
    func testResetError() async throws {
        var state = ResetPasswordReducer.State()
        state.resetPasswordCallState.firingFunc = NetCallReducer.mockFire(with: nil, error: NSError(domain: "Server", code: 401), delayMillis: 10)
        let store = TestStore(initialState: state) { ResetPasswordReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(password: ""))
        await store.send(.didTapReset) {
            $0.resetPasswordCallState.endpoint.postData = authData
            $0.isButtonEnabled = false
        }
        
        await store.receive(.resetPasswordCall(.fire)) {
            $0.resetPasswordCallState.isInProgress = true
        }
        
        await store.receive(.resetPasswordCall(.delegate(.error(NSError(domain: "Server", code: 401))))) {
            $0.resetPasswordCallState.isInProgress = false
            $0.isButtonEnabled = true
            $0.alert = AlertState { TextState("Error: 401") } actions: {} message: {
                TextState("Unauthorized")
            }
        }
        
        await store.finish()
    }
}
