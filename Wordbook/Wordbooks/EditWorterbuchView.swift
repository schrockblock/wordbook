//
//  EditWorterbuchView.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import SwiftUI
import ComposableArchitecture

struct EditWorterbuchView: View {
    @Bindable var store: StoreOf<EditWorterbuchReducer>
    
    var body: some View {
        HStack {
            TextField(text: $store.worterbuch.name) {
                Text("Name")
            }
                .padding()
            Spacer()
        }
    }
}

//#Preview {
//    EditWorterbuchView(store: Store(initialState: EditWorterbuchReducer.State(worterbuch: Worterbuch()), reducer: { EditWorterbuchReducer() }))
//}
