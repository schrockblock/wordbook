//
//  PhraseDetailsView.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import SwiftUI
import ComposableArchitecture

struct PhraseDetailsView: View {
    @Bindable var store: StoreOf<PhraseReducer>
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    PhraseDetailsView(store: Store(initialState: mockPhrases.first!, reducer: PhraseReducer.init))
}
