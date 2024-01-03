//
//  AddPhraseReducer.swift
//  WordbookAW Watch App
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

public struct AddPhraseReducer: Reducer {
    @Dependency(\.dismiss) var dismiss
    
    public struct State: Equatable {
        @PresentationState var alert: AlertState<Action.Alert>?
        
        @BindingState var text: String = ""
        @BindingState var translation: String = ""
    }
    
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        
        public enum Alert: Equatable {
            case confirmDiscard
            case confirmSave
        }
        
        public enum Delegate: Equatable {
            case savePhrase(Phrase)
        }
    }
    
    public enum RecordingStatus: Equatable {
        case text, translation
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDiscard)):
                return .run { send in
                    //await send(.delegate(.saveMeeting))
                    await self.dismiss()
                }
                
            case .alert(.presented(.confirmSave)):
                let text = state.text
                let translation = state.translation
                return .run { send in
                    await send(.delegate(.savePhrase(Phrase(id: text ?? "", translation: translation, createdAt: Date()))))
                    await self.dismiss()
                }
                
            case .alert(.dismiss):
                return .none
                
            case .delegate:
                return .none
                
            default: break
            }
            return .none
        }.ifLet(\.$alert, action: /Action.alert)
    }
}

extension AlertState where Action == AddPhraseReducer.Action.Alert {
  static func endMeeting(isDiscardable: Bool) -> Self {
    Self {
      TextState("End meeting?")
    } actions: {
      ButtonState(action: .confirmSave) {
        TextState("Save and end")
      }
      if isDiscardable {
        ButtonState(role: .destructive, action: .confirmDiscard) {
          TextState("Discard")
        }
      }
      ButtonState(role: .cancel) {
        TextState("Resume")
      }
    } message: {
      TextState("You are ending the meeting early. What would you like to do?")
    }
  }
}
