//
//  AddPhraseView.swift
//  WordbookAW Watch App
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
                TextField(text: viewStore.$text) {
                    Text("Phrase")
                }
                TextField(text: viewStore.$translation) {
                    Text("Translation")
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
