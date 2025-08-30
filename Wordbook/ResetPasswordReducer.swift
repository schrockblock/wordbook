//
//  ResetPasswordReducer.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import Foundation
import ComposableArchitecture
import FunNetCore
import FunNetTCA
import ErrorHandling

func resetPasswordEndpoint() -> Endpoint {
    var endpoint = Endpoint()
    endpoint.method = .post
    endpoint.path = "forgot_password"
    return endpoint
}

@Reducer
public struct ResetPasswordReducer {
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var password: String = ""
        var confirmPassword: String = ""
        
        var resetPasswordCallState = NetCallReducer.State(session: Current.session,
                                                          baseUrl: Current.baseUrl,
                                                          endpoint: resetPasswordEndpoint(),
                                                          firingFunc: NetCallReducer.mockFire(with: mockUser.data(using: .utf8)))
        
        var isButtonEnabled = false
    }
    
    public enum Action: BindableAction, Sendable, Equatable {
        case binding(BindingAction<State>)
        case resetPasswordCall(NetCallReducer.Action)
        
        case didTapReset
        
        case delegate(Delegate)
        
        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable, Sendable {}
        
        public enum Delegate: Sendable, Equatable {
            case didReset
        }
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.password) { oldValue, newValue in
                Reduce { state, action in
                    state.isButtonEnabled = !newValue.isEmpty && state.confirmPassword == newValue
                    return .none
                }
            }
            .onChange(of: \.confirmPassword) { oldValue, newValue in
                Reduce { state, action in
                    state.isButtonEnabled = !newValue.isEmpty && state.password == newValue
                    return .none
                }
            }
        Scope(state: \ResetPasswordReducer.State.resetPasswordCallState, action: /ResetPasswordReducer.Action.resetPasswordCall, child: NetCallReducer.init)
        Reduce { state, action in
            state.isButtonEnabled = !(state.confirmPassword.isEmpty || state.password.isEmpty) && !state.resetPasswordCallState.isInProgress
            switch action {
            case .didTapReset:
                let authData = try? JSONEncoder().encode(User(password: state.password))
                state.resetPasswordCallState.endpoint.postData = authData
                state.isButtonEnabled = false
                return .send(.resetPasswordCall(.fire))
            case .resetPasswordCall(.delegate(.responseData(let data))):
                state.isButtonEnabled = true
                if let user = try? defaultJsonDecoder().decode(User.self, from: data), let _ = user.apiKey {
                    return .send(.delegate(.didReset))
                }
            case .resetPasswordCall(.delegate(.error(let error as NSError))):
                state.isButtonEnabled = true
                var allErrors = urlLoadingErrorCodesDict
                allErrors.merge(urlResponseErrorMessages, uniquingKeysWith: { _, second in second })
                if let message = allErrors[error.code] {
                    state.alert = AlertState { TextState("Error: \(error.code)") } actions: {} message: {
                        TextState(message)
                    }
                }
                break
            default: break
            }
            return .none
        }.ifLet(\.$alert, action: \.alert)
    }
}

