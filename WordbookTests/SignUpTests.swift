//
//  SignUpTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import ComposableArchitecture
import FunNetTCA
@testable import Template

@MainActor
final class SignUpTests: XCTestCase {
    func testButtonEnabled() async throws {
        var state = SignUpReducer.State()
        state.signUpCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { SignUpReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.binding(.set(\.username, "elliot"))) {
            $0.username = "elliot"
        }
        await store.send(.binding(.set(\.password, "test"))) {
            $0.password = "test"
            $0.isButtonEnabled = true
        }
        await store.send(.binding(.set(\.password, ""))) {
            $0.password = ""
            $0.isButtonEnabled = false
        }
        await store.send(.binding(.set(\.password, "test"))) {
            $0.password = "test"
            $0.isButtonEnabled = true
        }
        
        await store.finish()
    }
    
    func testSignUp() async throws {
        var state = SignUpReducer.State()
        state.signUpCallState.firingFunc = NetCallReducer.mockFire(with: mockUser.data(using: .utf8), delayMillis: 10)
        let store = TestStore(initialState: state) { SignUpReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: "", password: ""))
        await store.withExhaustivity(.off(showSkippedAssertions: true)) {
            await store.send(.didTapSignUp)// {
//                // JSONEncoder changes the order of the keys from run to run, causing this test to fail if exhaustive
//                $0.loginCallState.endpoint.postData = authData
//            }
        }
        
        await store.receive(.signUpCall(.fire)) {
            $0.signUpCallState.isInProgress = true
        }
        
        await store.receive(.signUpCall(.delegate(.responseData(mockUser.data(using: .utf8)!)))) {
            $0.isButtonEnabled = true
            $0.signUpCallState.isInProgress = false
        }
        await store.receive(.delegate(.advanceAuthed))
        
        await store.finish()
    }
    
    func testSignUpError() async throws {
        var state = SignUpReducer.State()
        state.signUpCallState.firingFunc = NetCallReducer.mockFire(with: nil, error: NSError(domain: "Server", code: 401), delayMillis: 10)
        let store = TestStore(initialState: state) { SignUpReducer() } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        let authData = try? JSONEncoder().encode(User(username: "", password: ""))
        await store.withExhaustivity(.off(showSkippedAssertions: true)) {
            await store.send(.didTapSignUp)// {
//                // JSONEncoder changes the order of the keys from run to run, causing this test to fail if exhaustive
//                $0.loginCallState.endpoint.postData = authData
//            }
        }
        
        await store.receive(.signUpCall(.fire)) {
            $0.signUpCallState.isInProgress = true
        }
        
        await store.receive(.signUpCall(.delegate(.error(NSError(domain: "Server", code: 401))))) {
            $0.isButtonEnabled = true
            $0.signUpCallState.isInProgress = false
            $0.alert = AlertState { TextState("Error: 401") } actions: {} message: {
                TextState("Unauthorized")
            }
        }
        
        await store.finish()
    }
}
