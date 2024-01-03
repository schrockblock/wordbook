//
//  AddPhraseView.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

struct AddPhraseView: View {
    let store: StoreOf<AddPhraseReducer>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                Section("Text") {
                    VStack {
                        Button(action: { viewStore.send(.toggleRecordingPhrase) }) {
                            Image(systemName: viewStore.recording == .text ? "mic.fill" : "mic").frame(width: 90, height: 90)
                        }
                        .frame(width: UIScreen.main.bounds.width - 80, height: UIScreen.main.bounds.height / 2 - 190)
                        Text(viewStore.text ?? "").foregroundColor(.secondary)
                    }
                }
                Section("Translation") {
                    VStack {
                        Button(action: { viewStore.send(.toggleRecordingTranslation) }) {
                            Image(systemName: viewStore.recording == .translation ? "mic.fill" : "mic")
                        }
                        .frame(width: UIScreen.main.bounds.width - 80, height: UIScreen.main.bounds.height / 2 - 190)
                        Text(viewStore.translation ?? "").foregroundColor(.secondary)
                    }
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
