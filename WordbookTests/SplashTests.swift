//
//  SplashTests.swift
//  TemplateTests
//
//  Created by Elliot Schrock on 2/9/24.
//

import XCTest
import ComposableArchitecture
@testable import Wordbook

@MainActor
final class SplashTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "apiKey")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "apiKey")
        super.tearDown()
    }

    func testUnauthed() async throws {
        UserDefaults.standard.removeObject(forKey: "apiKey")
        let state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.didAppear)
        await store.receive(\.advanceUnauthed) {
            $0.landing = LandingReducer.State()
        }
    }

    func testAuthed() async throws {
        let state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        UserDefaults.standard.setValue("0123456789afedc".data(using: .utf8), forKey: "apiKey")
        await store.send(.didAppear)
        await store.receive(\.advanceAuthed) {
            $0.authed = AddableListReducer.State(
                phraseToItemState: { $0 },
                phraseToSearchableString: { "\($0.id) \($0.translation)" }
            )
        }
        UserDefaults.standard.removeObject(forKey: "apiKey")
    }

    func testAdvanceUnauthedSetsLanding() async throws {
        let state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.advanceUnauthed) {
            $0.landing = LandingReducer.State()
        }
    }

    func testAdvanceAuthedBuildsListState() async throws {
        let state = SplashReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.advanceAuthed)

        XCTAssertNotNil(store.state.authed)
        let sample = Phrase(id: "a", translation: "b", createdAt: Date())
        XCTAssertEqual(store.state.authed?.phraseToSearchableString?(sample), "a b")
        // phraseToItemState should pass the phrase through unchanged.
        XCTAssertEqual(store.state.authed?.phraseToItemState(sample).id, "a")
    }

    func testAuthedClearsLeftoverPresentationViaLogin() async throws {
        var state = SplashReducer.State()
        state.login = LoginReducer.State()
        var landing = LandingReducer.State()
        landing.login = LoginReducer.State()
        state.landing = landing
        state.reset = ResetPasswordReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.landing(.presented(.login(.presented(.delegate(.advanceAuthed))))))

        XCTAssertNil(store.state.login)
        XCTAssertNil(store.state.landing)
        XCTAssertNil(store.state.reset)
        XCTAssertNotNil(store.state.authed)
        let sample = Phrase(id: "a", translation: "b", createdAt: Date())
        XCTAssertEqual(store.state.authed?.phraseToSearchableString?(sample), "a b")
    }

    func testAuthedClearsLeftoverPresentationViaSignUp() async throws {
        var state = SplashReducer.State()
        state.login = LoginReducer.State()
        var landing = LandingReducer.State()
        landing.signUp = SignUpReducer.State()
        state.landing = landing
        state.reset = ResetPasswordReducer.State()
        let store = TestStore(initialState: state) {
            SplashReducer()
        } withDependencies: {
            $0.mainQueue = .immediate
        }
        store.exhaustivity = .off(showSkippedAssertions: true)

        await store.send(.landing(.presented(.signUp(.presented(.delegate(.advanceAuthed))))))

        XCTAssertNil(store.state.login)
        XCTAssertNil(store.state.landing)
        XCTAssertNil(store.state.reset)
        XCTAssertNotNil(store.state.authed)
    }
}
