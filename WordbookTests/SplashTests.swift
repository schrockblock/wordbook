//
//  SplashTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import ComposableArchitecture
@testable import Template

@MainActor
final class SplashTests: XCTestCase {
    func testUnauthed() async throws {
        var state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        await store.send(.didAppear)
        await store.receive(.advanceUnauthed) {
            $0.landing = LandingReducer.State()
        }
    }
    
    func testAuthed() async throws {
        var state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        
        UserDefaults.standard.setValue("0123456789afedc".data(using: .utf8), forKey: "apiKey")
        await store.send(.didAppear)
        await store.receive(.advanceAuthed) {
            $0.authed = TabsReducer.State()
        }
    }
}
