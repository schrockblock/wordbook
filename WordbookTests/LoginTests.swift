//
//  LoginTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/8/24.
//

import XCTest
import ComposableArchitecture
import FunNetTCA
@testable import Template

@MainActor
final class LoginTests: XCTestCase {
    func testLoginEnabled() async throws {
        var state = LoginReducer.State()
        state.loginCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { LoginReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.binding(.set(\.username, "elliot"))) {
            $0.username = "elliot"
        }
        await store.send(.binding(.set(\.password, "test"))) {
            $0.password = "test"
            $0.isLoginButtonEnabled = true
        }
        await store.send(.binding(.set(\.password, ""))) {
            $0.password = ""
            $0.isLoginButtonEnabled = false
        }
        await store.send(.binding(.set(\.password, "test"))) {
            $0.password = "test"
            $0.isLoginButtonEnabled = true
        }
        
        await store.finish()
    }
    
    func testLogin() async throws {
        var state = LoginReducer.State(username: "elliot", password: "password", isLoginButtonEnabled: true)
        state.loginCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { LoginReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: "elliot", password: "password"))
        await store.withExhaustivity(.off(showSkippedAssertions: true)) {
            await store.send(.didTapLogin)// {
//                // JSONEncoder changes the order of the keys from run to run, causing this test to fail if exhaustive
//                $0.loginCallState.endpoint.postData = authData
//            }
        }
        
        await store.receive(.loginCall(.fire)) {
            $0.loginCallState.isInProgress = true
            $0.isLoginButtonEnabled = false
        }
        
        await store.receive(.loginCall(.delegate(.responseData(mockUser.data(using: .utf8)!)))) {
            $0.loginCallState.isInProgress = false
            $0.isLoginButtonEnabled = true
        }
        await store.receive(.delegate(.advanceAuthed))
        
        await store.finish()
    }
    
    func testLoginError() async throws {
        var state = LoginReducer.State(username: "elliot", password: "password", isLoginButtonEnabled: true)
        state.loginCallState.firingFunc = NetCallReducer.mockFire(with: nil, error: NSError(domain: "Server", code: 401), delayMillis: 10)
        let store = TestStore(initialState: state) { LoginReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: "", password: ""))
        await store.withExhaustivity(.off(showSkippedAssertions: true)) {
            await store.send(.didTapLogin)// {
//                // JSONEncoder changes the order of the keys from run to run, causing this test to fail if exhaustive
//                $0.loginCallState.endpoint.postData = authData
//            }
        }
        
        await store.receive(.loginCall(.fire)) {
            $0.loginCallState.isInProgress = true
            $0.isLoginButtonEnabled = false
        }
        
        await store.receive(.loginCall(.delegate(.error(NSError(domain: "Server", code: 401))))) {
            $0.loginCallState.isInProgress = false
            $0.isLoginButtonEnabled = true
            $0.alert = AlertState { TextState("Error: 401") } actions: {} message: {
                TextState("Incorrect username or password")
            }
        }
        
        await store.finish()
    }

}
