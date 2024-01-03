//
//  PhrasesView.swift
//  WordbookAW Watch App
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

struct PhrasesView: View {
    let store: StoreOf<PhrasesReducer>
    
    public init(store: StoreOf<PhrasesReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                HStack {
                    Button(action: { viewStore.send(.addPhrase) }) {
                        Image(systemName: "plus")
                    }
                }
                PhraseListView(store: store.scope(state: \.phrases, action: PhrasesReducer.Action.list))
                    .sheet(store: self.store.scope(state: \.$addState, action: { .add($0) })) { addStore in
                        NavigationStack {
                            AddPhraseView(store: addStore)
                                .navigationTitle("New phrase")
                                .toolbar {
                                    ToolbarItem {
                                        Button("Save") { viewStore.send(.savePhrase) }
                                    }
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") { viewStore.send(.cancelPhrase) }
                                    }
                                }
                        }
                    }
            }
        }
    }
}

struct PhrasesView_Previews: PreviewProvider {
    static var previews: some View {
        PhrasesView(store: Store(initialState: PhrasesReducer.State(phrases: mockPhrases), reducer: { PhrasesReducer() }))
    }
}
