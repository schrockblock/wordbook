//
//  LandingView.swift
//  Template
//
//  Created by Elliot Schrock on 2/8/24.
//

import SwiftUI
import ComposableArchitecture

struct LandingView: View {
    @Bindable var store: StoreOf<LandingReducer>
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "text.book.closed.fill").resizable()
                    .foregroundColor(.white)
                    .aspectRatio(contentMode: .fit)
                    .padding(.top, 100)
                    .padding(.leading, 32)
                    .padding(.trailing, 32)
                Spacer()
            }
            Spacer()
            HStack {
                Button(action: { store.send(.didTapLogin) }, label: {
                    Text("Login")
                })
                .buttonStyle(ActionButton())
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 8))
                Spacer()
                Button(action: { store.send(.didTapSignUp) }, label: {
                    Text("Sign up")
                })
                .buttonStyle(SecondaryButton())
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 16))
            }
        }
        .background(Color.primaryBg)
        .navigationDestination(item: $store.scope(state: \.login, action: \.login)) { store in
            LoginView(store: store).navigationBarHidden(true)
        }
        .navigationDestination(item: $store.scope(state: \.signUp, action: \.signUp)) { store in
            SignUpView(store: store)
        }
    }
}

#Preview {
    NavigationStack {
        LandingView(store: Store(initialState: LandingReducer.State(), reducer: {
            LandingReducer()._printChanges()
        }))
    }
}
