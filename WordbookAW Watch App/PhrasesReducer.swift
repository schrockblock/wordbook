//
//  PhrasesReducer.swift
//  WordbookAW Watch App
//
//  Created by Elliot Schrock on 9/21/23.
//

import ComposableArchitecture
import CasePaths
import Foundation

public struct PhrasesReducer: Reducer {
    public struct State: Equatable {
        @PresentationState var addState: AddPhraseReducer.State?
        var phrases = PhraseListReducer.State()
        
        public init(phrases: [Phrase]? = nil) {
            self.phrases = phrases != nil ? PhraseListReducer.State(data: phrases!) : PhraseListReducer.State()
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case addPhrase
        case savePhrase
        case cancelPhrase
        case list(PhraseListReducer.Action)
        case add(PresentationAction<AddPhraseReducer.Action>)
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.phrases, action: /PhrasesReducer.Action.list) {
            PhraseListReducer()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case .addPhrase:
                state.addState = AddPhraseReducer.State()
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
            }
        }.ifLet(\.$addState, action: /Action.add) {
            AddPhraseReducer()
        }
    }
    
    public init() {}
}
