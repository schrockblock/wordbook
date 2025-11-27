//
//  AddPhraseView.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

struct AddPhraseView: View {
    @Bindable var store: StoreOf<AddPhraseReducer>
    
    var body: some View {
        List {
            Section("Text") {
                VStack {
                    Button(action: { store.send(.toggleRecordingPhrase) }) {
                        Image(systemName: store.recording == .text ? "mic.fill" : "mic").frame(width: 90, height: 90)
                    }
                    .frame(width: UIScreen.main.bounds.width - 80, height: UIScreen.main.bounds.height / 2 - 190)
                    TextField("Phrase", text: $store.text).foregroundColor(.secondary)
                }
            }
            Section("Translation") {
                VStack {
                    Button(action: { store.send(.toggleRecordingTranslation) }) {
                        Image(systemName: store.recording == .translation ? "mic.fill" : "mic")
                    }
                    .frame(width: UIScreen.main.bounds.width - 80, height: UIScreen.main.bounds.height / 2 - 190)
                    TextField("Translation", text: $store.translation).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AddPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        AddPhraseView(store: Store(initialState: AddPhraseReducer.State(), reducer: { AddPhraseReducer() }))
    }
}
