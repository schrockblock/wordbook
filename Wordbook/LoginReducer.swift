//
//  LoginReducer.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import Foundation
import ComposableArchitecture
import FunNetCore
import FunNetTCA
import ErrorHandling

func sessionsEndpoint() -> Endpoint {
    var endpoint = Endpoint()
    endpoint.method = .post
    endpoint.path = "sessions"
    return endpoint
}

let mockUser = """
{"api_key": "abcdef1234567890"}
"""

@Reducer
public struct LoginReducer {
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var forgot: ForgotPasswordReducer.State?
        @Presents public var signUp: SignUpReducer.State?
        @Presents var alert: AlertState<Action.Alert>?
        
        var username: String = ""
        var password: String = ""
        
        var loginCallState = NetCallReducer.State(session: Current.session,
                                                  baseUrl: Current.baseUrl,
                                                  endpoint: sessionsEndpoint(),
                                                  firingFunc: NetCallReducer.mockFire(with: mockUser.data(using: .utf8)))
        
        var isLoginButtonEnabled = false
        
        let tAndC: String = ""
        let privacyPolicy: String = ""
    }
    
    public enum Action: BindableAction, Sendable, Equatable {
        case forgot(PresentationAction<ForgotPasswordReducer.Action>)
        case signUp(PresentationAction<SignUpReducer.Action>)
        case binding(BindingAction<State>)
        case loginCall(NetCallReducer.Action)
        
        case didTapLogin
        case didTapPrivacy
        case didTapTerms
        case didTapForgot
        case didTapSignUp
        
        case delegate(Delegate)
        
        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable, Sendable {}
        
        public enum Delegate: Sendable, Equatable {
            case advanceAuthed
            case signUp
            case loadUrl(String)
        }
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.username) { oldValue, newValue in
                Reduce { state, action in
                    state.isLoginButtonEnabled = !(state.password.isEmpty || newValue.isEmpty)
                    return .none
                }
            }.onChange(of: \.password) { oldValue, newValue in
                Reduce { state, action in
                    state.isLoginButtonEnabled = !(state.username.isEmpty || newValue.isEmpty)
                    return .none
                }
            }
        Scope(state: \LoginReducer.State.loginCallState, action: /LoginReducer.Action.loginCall, child: NetCallReducer.init)
        Reduce { state, action in
            state.isLoginButtonEnabled = !(state.username.isEmpty || state.password.isEmpty) && !state.loginCallState.isInProgress
            switch action {
            case .didTapLogin:
                let authData = try? Current.apiJsonEncoder.encode(User(username: state.username, password: state.password))
                state.loginCallState.endpoint.postData = authData
                return .send(.loginCall(.fire))
            case .loginCall(.delegate(.responseData(let data))):
                if let user = try? Current.apiJsonDecoder.decode(User.self, from: data), let _ = user.apiKey {
                    return .send(.delegate(.advanceAuthed))
                }
            case .loginCall(.delegate(.error(let error as NSError))):
                var allErrors = urlLoadingErrorCodesDict
                allErrors.merge(urlResponseErrorMessages, uniquingKeysWith: { _, second in second })
                allErrors[401] = "Incorrect username or password"
                allErrors[403] = "Incorrect username or password"
                if let message = allErrors[error.code] {
                    state.alert = AlertState { TextState("Error: \(error.code)") } actions: {} message: {
                        TextState(message)
                    }
                }
            case .didTapTerms:
                return .send(.delegate(.loadUrl(state.tAndC)))
            case .didTapPrivacy:
                return .send(.delegate(.loadUrl(state.privacyPolicy)))
            case .didTapSignUp:
                state.signUp = .init()
            case .didTapForgot:
                state.forgot = .init()
            case .forgot(.presented(.delegate(.didReset))):
                state.forgot = nil
            case .signUp(_): break
            case .forgot(_): break
            case .binding(_): break
            case .loginCall(_): break
            case .alert: break
            case .delegate(_): break
            }
            return .none
        }.ifLet(\.$signUp, action: \.signUp) {
            SignUpReducer()
        }.ifLet(\.$forgot, action: \.forgot) {
            ForgotPasswordReducer()
        }.ifLet(\.$alert, action: \.alert)
    }
}
