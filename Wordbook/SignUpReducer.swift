//
//  SignUpReducer.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import Foundation
import ComposableArchitecture
import FunNetCore
import FunNetTCA
import ErrorHandling

func postUsersEndpoint() -> Endpoint {
    var endpoint = Endpoint()
    endpoint.method = .post
    endpoint.path = "users"
    return endpoint
}

@Reducer
public struct SignUpReducer {
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var username: String = ""
        var password: String = ""
        
        var signUpCallState = NetCallReducer.State(session: Current.session,
                                                   baseUrl: Current.baseUrl,
                                                   endpoint: postUsersEndpoint(),
                                                   firingFunc: NetCallReducer.mockFire(with: mockUser.data(using: .utf8)))
        
        var isButtonEnabled = false
        
        let tAndC: String = ""
        let privacyPolicy: String = ""
    }
    
    public enum Action: BindableAction, Sendable, Equatable {
        case binding(BindingAction<State>)
        case signUpCall(NetCallReducer.Action)
        
        case didTapPrivacy
        case didTapTerms
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
                    state.isButtonEnabled = !(state.password.isEmpty || newValue.isEmpty)
                    return .none
                }
            }.onChange(of: \.password) { oldValue, newValue in
                Reduce { state, action in
                    state.isButtonEnabled = !(state.username.isEmpty || newValue.isEmpty)
                    return .none
                }
            }
        Scope(state: \SignUpReducer.State.signUpCallState, action: /SignUpReducer.Action.signUpCall, child: NetCallReducer.init)
        Reduce { state, action in
            switch action {
            case .didTapSignUp:
                let authData = try? JSONEncoder().encode(User(username: state.username, password: state.password))
                state.signUpCallState.endpoint.postData = authData
                state.isButtonEnabled = false
                return .send(.signUpCall(.fire))
            case .signUpCall(.delegate(.responseData(let data))):
                state.isButtonEnabled = true
                if let user = try? defaultJsonDecoder().decode(User.self, from: data), let _ = user.apiKey {
                    return .send(.delegate(.advanceAuthed))
                }
            case .signUpCall(.delegate(.error(let error as NSError))):
                state.isButtonEnabled = true
                var allErrors = urlLoadingErrorCodesDict
                allErrors.merge(urlResponseErrorMessages, uniquingKeysWith: { _, second in second })
                if let message = allErrors[error.code] {
                    state.alert = AlertState { TextState("Error: \(error.code)") } actions: {} message: {
                        TextState(message)
                    }
                }
                break
            case .didTapTerms:
                return .send(.delegate(.loadUrl(state.tAndC)))
            case .didTapPrivacy:
                return .send(.delegate(.loadUrl(state.privacyPolicy)))
            default: break
            }
            return .none
        }.ifLet(\.$alert, action: \.alert)
    }
}
