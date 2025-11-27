//
//  AddableListView.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import SwiftUI
import ComposableArchitecture

let margin: CGFloat = 16
struct AddableListView<RowContent: View,
                       AddContent: View,
                       EditContent: View,
                       DetailsContent: View>: View {
    @Environment(\.scenePhase) var scenePhase
    let title: String
    @Bindable var store: StoreOf<AddableListReducer>
    let rowContent: (Phrase) -> RowContent
    let detailsContent: (Phrase) -> DetailsContent
    let addContent: (StoreOf<EditPhraseReducer>) -> AddContent
    let editContent: (StoreOf<EditPhraseReducer>) -> EditContent
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.displayedPhrases) { phrase in
                    PhraseView(phrase: phrase)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(action: { store.send(.removePhrase(id: phrase.id)) }) {
                                    Text("Delete")
                                }
                                .tint(Color.red)
                            }
                        .onTapGesture {
                            store.send(.editPhrase(id: phrase.id))
                        }
                }
            }
            .navigationTitle(title)
            .toolbar {
                HStack {
                    Spacer()
                    Button(action: { store.send(.sortByRecent) }) {
                        Image(systemName: store.sortScheme == .recent ? "clock.fill" : "clock")
                    }
                    Button(action: { store.send(.sortByAlphabet) }) {
                        Image(systemName: store.sortScheme == .alphabet ? "a.square.fill" : "a.square")
                    }
                    Button(action: { store.send(.addNewTapped) }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .onAppear {
                store.send(.didAppear)
            }
//            .navigationDestination(item: $store.scope(state: \.details, action: \.details)) { store in
//                detailsContent(store)
//            }
            .sheet(item: $store.scope(state: \.new, action: \.add)) { addStore in
                NavigationStack {
                    addContent(addStore)
                        .navigationTitle("New phrase")
                        .toolbar {
                            ToolbarItem {
                                Button("Save") {
//                                    withAnimation {
                                        store.send(.saveNew)
//                                    }
                                }
                                    .disabled(store.edit?.isSaveDisabled == true)
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { store.send(.cancel) }
                            }
                        }
                }
            }
            .sheet(item: $store.scope(state: \.edit, action: \.edit)) { editStore in
                NavigationStack {
                    editContent(editStore)
                        .navigationTitle("Edit phrase")
                        .toolbar {
                            ToolbarItem {
                                Button("Save") { store.send(.saveEdit) }
                                    .disabled(store.edit?.isSaveDisabled == true)
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { store.send(.cancel) }
                            }
                        }
                }
            }
        }
        .searchable(text: $store.localFilter)
        .onChange(of: scenePhase) {
            store.send(.didChangeScenePhase)
        }
    }
}

#Preview {
    AddableListView(title: "Phrases", store: Store(initialState: AddableListReducer.State(data: mockPhrases, phraseToItemState: { $0 }, phraseToSearchableString: { "\($0.id) \($0.translation)" }), reducer: AddableListReducer.init), rowContent: PhraseView.init, detailsContent: PhraseView.init, addContent: EditPhraseView.init, editContent: EditPhraseView.init)
}
