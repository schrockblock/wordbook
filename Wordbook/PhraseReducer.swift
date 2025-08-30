//
//  PhraseReducer.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct PhraseReducer {
    typealias State = Phrase
//    struct State: Equatable, Identifiable {
//        var id: String
//        var phrase: Phrase
//        
//        init(phrase: Phrase) {
//            self.id = phrase.id
//            self.phrase = phrase
//        }
//    }
    
    enum Action: Equatable {
        case didTap
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case didTap(Phrase)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didTap:
                return .send(.delegate(.didTap(state)))
            case .delegate(_): break
            }
            
            return .none
        }
    }
}
