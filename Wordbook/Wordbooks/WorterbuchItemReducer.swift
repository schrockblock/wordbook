//
//  WorterbuchItemReducer.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct WorterbuchItemReducer {
    @ObservableState
    public struct State: Equatable, Identifiable {
        var worterbuch: Worterbuch
        // Derived from the wrapped wordbook so List taps in WorterbuchListView
        // route through `state.allWorterbuchs[id:]` correctly.
        public var id: UUID { worterbuch.id }
    }
    public enum Action: Equatable {
        case didTap
    }
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didTap: break
            }
            return .none
        }
    }
}
