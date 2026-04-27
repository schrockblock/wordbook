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
        Form {
            Section("Name") {
                TextField("Name", text: $store.worterbuch.name)
            }
            Section("Target language") {
                Picker("Language", selection: $store.worterbuch.targetLanguage) {
                    ForEach(Language.allCases.filter { $0 != .english }, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }
        }
    }
}

//#Preview {
//    EditWorterbuchView(store: Store(initialState: EditWorterbuchReducer.State(worterbuch: Worterbuch(name: "", key: "")), reducer: { EditWorterbuchReducer() }))
//}
