//
//  LoginView.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
    @Bindable var store: StoreOf<LoginReducer>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "text.book.closed.fill").resizable()
                        .foregroundStyle(Color.white)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .padding(.top, 16)
                    Spacer()
                }
                ProgressView()
                    .opacity(store.loginCallState.isInProgress ? 1 : 0)
                TextField("Username", text: $store.username)
                    .padding(8)
                    .background(Color.textBg)
                    .cornerRadius(8)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                SecureField("Password", text: $store.password)
                    .padding(8)
                    .background(Color.textBg)
                    .cornerRadius(8)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                HStack {
                    Spacer()
                    Button(action: { store.send(.didTapForgot) }) {
                        Text("Forgot password").padding(.trailing, 12)
                    }
                }
                Button(action: { store.send(.didTapLogin) }, label: {
                    Text("Login")
                })
                .buttonStyle(ActionButton())
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                Button(action: { store.send(.didTapSignUp) }, label: {
                    Text("Sign up")
                })
                .buttonStyle(SecondaryButton())
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
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
            .navigationDestination(item: $store.scope(state: \.signUp, action: \.signUp)) { store in
                SignUpView(store: store)
            }
            .sheet(item: $store.scope(state: \.forgot, action: \.forgot)) { store in
                ForgotPasswordView(store: store).navigationBarHidden(true)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        }
    }
}

#Preview {
    LoginView(store: Store(initialState: LoginReducer.State(), reducer: { LoginReducer() }))
}
