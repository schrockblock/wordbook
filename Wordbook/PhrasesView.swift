//
//  PhrasesView.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

@available(iOS 15.0, *)
public struct PhrasesView: View {
    @Bindable
    var store: StoreOf<PhrasesReducer>
    
    public init(store: StoreOf<PhrasesReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            PhraseListView(store: store.scope(state: \.phrases, action: PhrasesReducer.Action.list))
                .toolbar(content: {
                    Spacer()
                    Text("Phrases")
                    Spacer()
                    Button(action: { store.send(PhrasesReducer.Action.list(.sortByRecent)) }) {
                        Image(systemName: store.state.phrases.sortScheme == .recent ? "clock.fill" : "clock")
                    }
                    Button(action: { store.send(PhrasesReducer.Action.list(.sortByAlphabet)) }) {
                        Image(systemName: store.state.phrases.sortScheme == .alphabet ? "a.square.fill" : "a.square")
                    }
                    Button(action: { store.send(PhrasesReducer.Action.addPhrase) }, label: {
                        Image(systemName: "plus")
                    })
                })
//                .searchable(text: $store.localFilter)
                .sheet(store: self.store.scope(state: \.$addState, action: { .add($0) })) { addStore in
                    NavigationStack {
                        EditPhraseView(store: addStore)
                            .navigationTitle("New phrase")
                            .toolbar {
                                ToolbarItem {
                                    Button("Save") { store.send(.savePhrase) }
                                }
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { store.send(.cancelPhrase) }
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
