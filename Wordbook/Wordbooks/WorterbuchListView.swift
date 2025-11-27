//
//  WorterbuchListView.swift
//  Template
//
//  Created by Elliot Schrock on 4/18/24.
//

import SwiftUI
import ComposableArchitecture

struct WorterbuchListView: View {
    @Environment(\.scenePhase) var scenePhase
    let title: String
    @Bindable var store: StoreOf<WorterbuchListReducer>
    
    var body: some View {
        NavigationStack {
            List {
                ForEachStore(self.store.scope(state: \.displayedWorterbuchStates, action: WorterbuchListReducer.Action.worterbuch(_:_:))) { worterbuchStore in
                    WorterbuchRowView(store: worterbuchStore)
                        .onTapGesture {
                            self.store.send(.worterbuch(worterbuchStore.id, .didTap))
                        }
                }
            }
            .navigationTitle("Worterbuchs")
            .toolbar(content: {
                HStack {
                    Spacer()
                    Button(action: { store.send(.addNewTapped) }, label: {
                        Image(systemName: "plus")
                    })
                }
            })
            .navigationDestination(item: $store.scope(state: \.details, action: \.details)) { phrasesStore in
                AddableListView(title: "Phrases",
                                store: phrasesStore,
                                rowContent: PhraseView.init,
                                detailsContent: PhraseView.init,
                                addContent: EditPhraseView.init,
                                editContent: EditPhraseView.init)
            }
            .sheet(item: $store.scope(state: \.new, action: \.edit)) { store in
                EditWorterbuchView(store: store)
            }
        }
        .searchable(text: $store.localFilter)
        .onChange(of: scenePhase) {
            store.send(.didChangeScenePhase)
        }
    }
}
