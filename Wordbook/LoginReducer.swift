//
//  LoginReducer.swift
//  Wordbook
//
//  Created by Elliot Schrock on 11/20/23.
//

import Foundation
import ComposableArchitecture

public struct LoginReducer: Reducer {
    public struct State {
        @BindingState var username: String = ""
        @BindingState var password: String = ""
        
        var isLoginButtonEnabled = false
        var isLoading = false
        
        let tAndC: String = ""
        let privacyPolicy: String = ""
    }
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        case didTapLogin
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                
            }
            return .none
        }
    }
}
