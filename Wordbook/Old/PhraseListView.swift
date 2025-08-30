//
//  PhraseListView.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

public struct PhraseListView: View {
    public let store: StoreOf<PhraseListReducer>
    
    public init(store: StoreOf<PhraseListReducer>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List(viewStore.state.list) { phrase in
                VStack(alignment: .leading) {
                    Text(phrase.id)
                    Text(phrase.translation ?? "").foregroundColor(.secondary)
                }
            }
//            .searchable(text: )
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct PhraseListView_Previews: PreviewProvider {
    static var previews: some View {
        return PhraseListView(store: Store(initialState: PhraseListReducer.State(data: mockPhrases), reducer: { PhraseListReducer() }))
    }
}
