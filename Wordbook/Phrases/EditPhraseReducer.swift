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
    struct DebounceId: Hashable {}
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        var recording: RecordingStatus?
        
        var phrase: Phrase?
        var text: String = ""
        var translation: String = ""
        var englishTranslator: ((String) async throws -> TranslationSession.Response)?
        var englishSession: TranslationSession?
        var germanTranslator: ((String) async throws -> TranslationSession.Response)?
        var germanSession: TranslationSession?
        var isAutoTranslationOn: Bool = true
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
            && ((lhs.englishSession == nil && rhs.englishSession != nil) || (lhs.englishSession != nil && rhs.englishSession == nil))
            && ((lhs.germanSession == nil && rhs.germanSession != nil) || (lhs.germanSession != nil && rhs.germanSession == nil))
        }
    }
    
    public enum Action: BindableAction {
        case toggleRecordingPhrase
        case toggleRecordingTranslation
        case initializeEnglish(TranslationSession)
        case initializeGerman(TranslationSession)
        case germanTranslationResult(String)
        case englishTranslationResult(String)
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
                    if let translator = state.englishTranslator, state.isAutoTranslationOn {
                        let translation = state.translation
                        return .run { send in
                            await onTranslationChanged(translator, translation, send)
                        }
                    } else {
                        state.isSaveDisabled = newValue.isEmpty
                    }
                    return .none
                }
            }
            .onChange(of: \.text) { oldValue, newValue in
                Reduce { state, action in
                    if let translator = state.germanTranslator, state.isAutoTranslationOn {
                        let text = state.text
                        return .run { send in
                            await onTextChanged(translator, text, send)
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
                if state.translation.isEmpty {
                    state.englishSession = session
                    state.englishTranslator = session.translate
                }
                
            case let .initializeGerman(session):
                if state.text.isEmpty {
                    state.germanSession = session
                    state.germanTranslator = session.translate
                }
                
            case .toggleRecordingPhrase:
                SpeechClient.language = .german
                state.recording = state.recording == nil ? .text : nil
                
            case .toggleRecordingTranslation:
                SpeechClient.language = .english
                state.recording = state.recording == nil ? .translation : nil
                
            case let .germanTranslationResult(germanText):
                state.text = germanText
                
            case let .englishTranslationResult(englishText):
                state.translation = englishText
                
            case .alert(.presented(.confirmDiscard)):
                return .run { send in
                    await self.dismiss()
                }
                
            case .alert(.presented(.confirmSave)):
                let text = state.text
                let translation = state.translation
                return .run { send in
                    await send(
                        .delegate(
                            .savePhrase(
                                Phrase(id: text, translation: translation, createdAt: Date())
                            )
                        )
                    )
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
                        if let translator = state.germanTranslator {
                            let text = transcript
                            return .run { send in
                                await onTextChanged(translator, text, send)
                            }
                        } else {
                            state.isSaveDisabled = transcript.isEmpty
                        }
                    case .translation:
                        state.translation = transcript
                        if let translator = state.englishTranslator {
                            let translation = transcript
                            return .run { send in
                                await onTranslationChanged(translator, translation, send)
                            }
                        } else {
                            state.isSaveDisabled = transcript.isEmpty
                        }
                    }
                }
                return .none
                
            default: break
            }
            if state.recording != nil {
                return .run { send in
                    await self.onTask(send: send)
                }
                .cancellable(id: DebounceId(), cancelInFlight: true)
            }
            return .none
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    private func onTextChanged(_ translator: (String) async throws -> TranslationSession.Response, _ text: String, _ send: Send<Action>) async {
        if !text.isEmpty {
            do {
                let response = try await translator(text)
                await send(.englishTranslationResult(response.targetText))
            } catch {}
        } else {
            await send(.englishTranslationResult(""))
        }
    }
    
    private func onTranslationChanged(_ translator: (String) async throws -> TranslationSession.Response, _ translation: String, _ send: Send<Action>) async {
        if !translation.isEmpty {
            do {
                let response = try await translator(translation)
                await send(.germanTranslationResult(response.targetText))
            } catch {}
        } else {
            await send(.germanTranslationResult(""))
        }
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
                    } catch {}
                }
            }
        }
    }
}
