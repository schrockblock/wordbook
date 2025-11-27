//
//  WorterbuchRowView.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import SwiftUI
import ComposableArchitecture

struct WorterbuchRowView: View {
    @Bindable var store: StoreOf<WorterbuchItemReducer>
    
    var body: some View {
        WithPerceptionTracking {
            HStack {
                Text(store.worterbuch.name ?? "").padding()
                Spacer()
            }
        }
    }
}

//#Preview {
//    WorterbuchRowView(store: Store(initialState: WorterbuchItemReducer.State(worterbuch: Worterbuch()), reducer: { WorterbuchItemReducer() }))
//}
