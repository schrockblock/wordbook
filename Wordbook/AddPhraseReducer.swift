//
//  AddPhraseReducer.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import Speech
import ComposableArchitecture

public struct AddPhraseReducer: Reducer {
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.dismiss) var dismiss
    
    public struct State: Equatable {
        @PresentationState var alert: AlertState<Action.Alert>?
        var recording: RecordingStatus?
        
        var text: String?
        var translation: String?
    }
    
    public enum Action: Equatable {
        case toggleRecordingPhrase
        case toggleRecordingTranslation
        case speechResult(String)
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
        Reduce { state, action in
            switch action {
            case .toggleRecordingPhrase:
                SpeechClient.language = .german
                state.recording = state.recording == nil ? .text : nil
            case .toggleRecordingTranslation:
                SpeechClient.language = .english
                state.recording = state.recording == nil ? .translation : nil
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
                
            case let .speechResult(transcript):
                if let status = state.recording {
                    switch status {
                    case .text:
                        state.text = transcript
                    case .translation:
                        state.translation = transcript
                    }
                }
                return .none
                
            default: break
            }
            if state.recording != nil {
                return .run { send in
                    await self.onTask(send: send)
                }
            }
            return .none
        }.ifLet(\.$alert, action: /Action.alert)
    }
    
    private func onTask(send: Send<Action>) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let status = await self.speechClient.requestAuthorization()
                
                if status == SFSpeechRecognizerAuthorizationStatus.authorized.rawValue {
                    do {
                        for try await transcript in self.speechClient.start() {
                            await send(.speechResult(transcript))
                        }
                    } catch {
                        // TODO: Handle error
                    }
                }
            }
        }
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
