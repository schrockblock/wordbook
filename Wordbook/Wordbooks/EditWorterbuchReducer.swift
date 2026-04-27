//
//  EditWorterbuchReducer.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct EditWorterbuchReducer {
    @ObservableState
    public struct State: Equatable, Identifiable {
        var id = Current.uuid()
        var worterbuch: Worterbuch
    }
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
    }
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            default: break
            }
            return .none
        }
    }
}
