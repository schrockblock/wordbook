//
//  EditPhraseView.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import SwiftUI
import ComposableArchitecture
import Translation

enum EditFocusTargets: Hashable {
    case text, translation
}

let imageHeight: CGFloat = 90
struct EditPhraseView: View {
    @Bindable var store: StoreOf<EditPhraseReducer>
    @FocusState private var focusState: EditFocusTargets?// = FocusState<EditFocusTargets?>()
    
    var body: some View {
        List {
            if !store.autoTranslations.isEmpty {
                if focusState != .translation || !store.text.isEmpty {
                    Section("Text") {
                        HStack {
                            Button(action: { store.send(.toggleRecordingPhrase) }) {
                                Image(systemName: store.recording == .text ? "mic.fill" : "mic")
                                    .frame(width: imageHeight, height: imageHeight)
                            }
                            .frame(width: imageHeight, height: imageHeight)
                            TextField("Phrase", text: $store.text).foregroundColor(.secondary)
                                .focused($focusState, equals: .text)
                                .translationTask(TranslationSession.Configuration(source: .init(identifier: "de-DE"), target: .init(identifier: "en-US"))) { session in
                                    store.send(.initializeGerman(session))
                                }
                        }
                    }
                }
                if focusState != .text || !store.translation.isEmpty {
                    Section() {
                        HStack {
                            Button(action: { store.send(.toggleRecordingTranslation) }) {
                                Image(systemName: store.recording == .translation ? "mic.fill" : "mic")
                                    .frame(width: imageHeight, height: imageHeight)
                            }
                            .frame(width: imageHeight, height: imageHeight)
                            TextField("Translation", text: $store.translation).foregroundColor(.secondary)
                                .focused($focusState, equals: .translation)
                                .translationTask(TranslationSession.Configuration(source: .init(identifier: "en-US"), target: .init(identifier: "de-DE"))) { session in
                                    store.send(.initializeEnglish(session))
                                }
                        }
                    }
                }
                Section("Auto translations") {
                    ForEach(store.autoTranslations, id: \.self) { translation in
                        Text(translation)
                            .onTapGesture {
                                store.send(.chooseTranslation(translation))
                            }
                    }
                }
            } else {
                    Section("Text") {
                        HStack {
                            Button(action: { store.send(.toggleRecordingPhrase) }) {
                                Image(systemName: store.recording == .text ? "mic.fill" : "mic")
                                    .frame(width: imageHeight, height: imageHeight)
                            }
                            .frame(width: imageHeight, height: imageHeight)
                            TextField("Phrase", text: $store.text).foregroundColor(.secondary)
                                .focused($focusState, equals: .text)
                                .translationTask(TranslationSession.Configuration(source: .init(identifier: "de-DE"), target: .init(identifier: "en-US"))) { session in
                                    store.send(.initializeGerman(session))
                                }
                        }
                    }
                    Section() {
                        HStack {
                            Button(action: { store.send(.toggleRecordingTranslation) }) {
                                Image(systemName: store.recording == .translation ? "mic.fill" : "mic")
                                    .frame(width: imageHeight, height: imageHeight)
                            }
                            .frame(width: imageHeight, height: imageHeight)
                            TextField("Translation", text: $store.translation).foregroundColor(.secondary)
                                .focused($focusState, equals: .translation)
                                .translationTask(TranslationSession.Configuration(source: .init(identifier: "en-US"), target: .init(identifier: "de-DE"))) { session in
                                    store.send(.initializeEnglish(session))
                                }
                        }
                    }
            }
        }
    }
}

#Preview {
    EditPhraseView(store: Store(initialState: EditPhraseReducer.State(phrase: Phrase(id: "", translation: "The melon", createdAt: Date())), reducer: EditPhraseReducer.init))
}
