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
    @FocusState private var focusState: EditFocusTargets?
    
    var body: some View {
        List {
            Section("Text") {
                HStack {
                    Button(action: { store.send(.toggleRecordingPhrase) }) {
                        Image(systemName: store.recording == .text ? "mic.fill" : "mic")
                            .frame(width: imageHeight, height: imageHeight)
                    }
                    .frame(width: imageHeight, height: imageHeight)
                    TextField("Phrase", text: $store.text).foregroundColor(.secondary)
                        .focused($focusState, equals: .text)
                        .translationTask(TranslationSession.Configuration(source: .init(identifier: store.targetLanguage.rawValue), target: .init(identifier: Language.english.rawValue))) { session in
                            store.send(.initializeTarget(session))
                        }
                }
            }
            
            Section("Translation") {
                HStack {
                    Button(action: { store.send(.toggleRecordingTranslation) }) {
                        Image(systemName: store.recording == .translation ? "mic.fill" : "mic")
                            .frame(width: imageHeight, height: imageHeight)
                    }
                    .frame(width: imageHeight, height: imageHeight)
                    TextField("Translation", text: $store.translation).foregroundColor(.secondary)
                        .focused($focusState, equals: .translation)
                        .translationTask(TranslationSession.Configuration(source: .init(identifier: Language.english.rawValue), target: .init(identifier: store.targetLanguage.rawValue))) { session in
                            store.send(.initializeEnglish(session))
                        }
                }
            }
            
            HStack {
                Toggle(isOn: $store.isAutoTranslationOn) {
                    Text("Autotranslate")
                }
            }
        }
    }
}

#Preview {
    EditPhraseView(store: Store(initialState: EditPhraseReducer.State(phrase: Phrase(id: "", translation: "The melon", createdAt: Date())), reducer: EditPhraseReducer.init))
}
