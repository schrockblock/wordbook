//
//  SignUpView.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct SignUpView: View {
    @Bindable var store: StoreOf<SignUpReducer>
    
    var body: some View {
        VStack {
            TextField("Username", text: $store.username)
                .padding(8)
                .background(Color.textBg)
                .cornerRadius(8)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            SecureField("Password", text: $store.password)
                .padding(8)
                .background(Color.textBg)
                .cornerRadius(8)
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            ProgressView().opacity(store.signUpCallState.isInProgress ? 1 : 0)
            Button(action: { store.send(.didTapSignUp) }, label: {
                Text("Sign up")
            })
            .buttonStyle(ActionButton())
            .disabled(!store.isButtonEnabled)
            .padding()
            Spacer()
            HStack {
                if !store.privacyPolicy.isEmpty {
                    Button(action: { store.send(.didTapPrivacy) }, label: {
                        Text("Privacy Policy")
                    })
                    .padding()
                }
                Spacer()
                if !store.tAndC.isEmpty {
                    Button(action: { store.send(.didTapTerms) }, label: {
                        Text("Terms of Service")
                    })
                    .padding()
                }
            }
        }
        .background(Color.primaryBg)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    SignUpView(store: Store(initialState: SignUpReducer.State(), reducer: {
        SignUpReducer()
    }))
}
