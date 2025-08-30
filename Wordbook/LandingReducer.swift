//
//  LandingReducer.swift
//  Template
//
//  Created by Elliot Schrock on 2/8/24.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct LandingReducer {
    @ObservableState
    public struct State: Equatable {
        @Presents public var login: LoginReducer.State?
        @Presents public var signUp: SignUpReducer.State?
    }
    
    public enum Action: Equatable {
        case login(PresentationAction<LoginReducer.Action>)
        case signUp(PresentationAction<SignUpReducer.Action>)
        case didTapLogin
        case didTapSignUp
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didTapLogin:
                state.login = .init()
            case .didTapSignUp:
                state.signUp = .init()
            case .login(_): break
            case .signUp(_): break
            }
            return .none
        }.ifLet(\.$login, action: \.login) {
            LoginReducer()
        }.ifLet(\.$signUp, action: \.signUp) {
            SignUpReducer()
        }
    }
}
