//
//  EditPhraseReducer.swift
//  Wordbook
//
//  Created by Elliot Schrock on 10/19/23.
//

import Foundation
import Speech
import NaturalLanguage
import Translation
import ComposableArchitecture

@Reducer
public struct EditPhraseReducer {
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var recording: RecordingStatus?
        
        var phrase: Phrase?
        var text: String = ""
        var translation: String = ""
        var englishSession: TranslationSession?
        var germanSession: TranslationSession?
        var autoTranslations: [String] = []
        var isSaveDisabled: Bool = true
        
        init(phrase: Phrase? = nil) {
            self.phrase = phrase
            if let phrase {
                self.text = phrase.id
                self.translation = phrase.translation
            }
        }
        
        public static func == (lhs: EditPhraseReducer.State, rhs: EditPhraseReducer.State) -> Bool {
            return lhs.alert == rhs.alert
            && lhs.recording == rhs.recording
            && lhs.phrase == rhs.phrase
            && lhs.text == rhs.text
            && lhs.translation == rhs.translation
            && lhs.autoTranslations == rhs.autoTranslations
            && ((lhs.englishSession == nil && rhs.englishSession != nil) || (lhs.englishSession != nil && rhs.englishSession == nil))
            && ((lhs.germanSession == nil && rhs.germanSession != nil) || (lhs.germanSession != nil && rhs.germanSession == nil))
        }
    }
    
    public enum Action: BindableAction {
        case toggleRecordingPhrase
        case toggleRecordingTranslation
        case chooseTranslation(String)
        case initializeEnglish(TranslationSession)
        case initializeGerman(TranslationSession)
        case translationResult(String)
        case speechResult(String)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case binding(BindingAction<State>)
        
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
            .onChange(of: \.translation) { oldValue, newValue in
                Reduce { state, action in
                    if let session = state.englishSession, state.text.isEmpty {
                        let translation = state.translation
                        return .run { send in
                            if !translation.isEmpty {
                                do {
                                    let response = try await session.translate(translation)
                                    await send(.translationResult(response.targetText))
                                } catch {
                                    
                                }
                            }
                        }
                    } else {
                        state.isSaveDisabled = newValue.isEmpty
                    }
                    return .none
                }
            }
            .onChange(of: \.text) { oldValue, newValue in
                Reduce { state, action in
                    if let session = state.germanSession, state.translation.isEmpty {
                        let text = state.text
                        return .run { send in
                            if !text.isEmpty {
                                do {
                                    let response = try await session.translate(text)
                                    await send(.translationResult(response.targetText))
                                } catch {
                                    
                                }
                            }
                        }
                    } else {
                        state.isSaveDisabled = newValue.isEmpty
                    }
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case let .initializeEnglish(session):
                state.englishSession = session
                
            case let .initializeGerman(session):
                state.germanSession = session
                
            case let .chooseTranslation(id):
                if state.text.isEmpty {
                    state.text = id
                } else if state.translation.isEmpty {
                    state.translation = id
                }
                state.autoTranslations = []
                state.isSaveDisabled = false
                
            case .toggleRecordingPhrase:
                SpeechClient.language = .german
                state.recording = state.recording == nil ? .text : nil
                
            case .toggleRecordingTranslation:
                SpeechClient.language = .english
                state.recording = state.recording == nil ? .translation : nil
                
            case let .translationResult(result):
                state.autoTranslations = [result]
                
            case .alert(.presented(.confirmDiscard)):
                return .run { send in
                    await self.dismiss()
                }
                
            case .alert(.presented(.confirmSave)):
                let text = state.text
                let translation = state.translation
                return .run { send in
                    await send(.delegate(.savePhrase(Phrase(id: text, translation: translation, createdAt: Date()))))
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
