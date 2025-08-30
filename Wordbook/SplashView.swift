//
//  SplashView.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct SplashView: View {
    @Bindable var store: StoreOf<SplashReducer>
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "text.book.closed.fill").resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, 100)
                    Spacer()
                }
                Spacer()
            }
            .background(Color.accentColor)
            .onAppear {
                store.send(.didAppear)
            }
            .navigationDestination(item: $store.scope(state: \.login, action: \.login)) { store in
                LoginView(store: store).navigationBarHidden(true)
            }
            .navigationDestination(item: $store.scope(state: \.landing, action: \.landing)) { store in
                LandingView(store: store).navigationBarHidden(true)
            }
            .sheet(item: $store.scope(state: \.reset, action: \.reset)) { store in
                ResetPasswordView(store: store).navigationBarHidden(true)
            }
            .fullScreenCover(item: $store.scope(state: \.authed, action: \.authed)) { store in
                AddableListView(title: "Phrases",
                                store: store,
                                rowContent: PhraseView.init,
                                detailsContent: PhraseView.init,
                                addContent: EditPhraseView.init,
                                editContent: EditPhraseView.init)
            }
        }
    }
}

#Preview {
    SplashView(store: Store(initialState: SplashReducer.State(), reducer: { SplashReducer() }))
}
