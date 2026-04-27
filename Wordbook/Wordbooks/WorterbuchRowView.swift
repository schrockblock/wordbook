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
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.worterbuch.name)
                    Text("English ↔ \(store.worterbuch.targetLanguage.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                Spacer()
            }
        }
    }
}

//#Preview {
//    WorterbuchRowView(store: Store(initialState: WorterbuchItemReducer.State(worterbuch: Worterbuch(name: "Tiere", key: "k1")), reducer: { WorterbuchItemReducer() }))
//}
