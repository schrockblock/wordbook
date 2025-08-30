//
//  PhrasesReducer.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import Foundation
import ComposableArchitecture
import CasePaths

@available(iOS 15.0, *)
public struct PhrasesReducer: Reducer {
    @ObservableState
    public struct State: Equatable {
        @Presents var addState: EditPhraseReducer.State?
        var phrases = PhraseListReducer.State()
        
        public init(phrases: [Phrase]? = nil) {
            self.phrases = phrases != nil ? PhraseListReducer.State(data: phrases!) : PhraseListReducer.State()
        }
    }
    
    public enum Action: BindableAction {
        case onAppear
        case addPhrase
        case savePhrase
        case cancelPhrase
        case binding(BindingAction<State>)
        case list(PhraseListReducer.Action)
        case add(PresentationAction<EditPhraseReducer.Action>)
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Scope(state: \.phrases, action: /PhrasesReducer.Action.list) {
            PhraseListReducer()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .addPhrase:
                state.addState = EditPhraseReducer.State()
                return .none
            case .list(_), .add(_):
                return .none
            case .savePhrase:
                let phrase = Phrase(id: state.addState?.text ?? "", translation: state.addState?.translation ?? "", createdAt: Date())
                state.addState = nil
                return .send(.list(.addPhrase(phrase)))
            case .cancelPhrase:
                state.addState = nil
                return .none
            case .binding(_): return .none
            }
        }.ifLet(\.$addState, action: /Action.add) {
            EditPhraseReducer()
        }
    }
    
    public init() {}
}
