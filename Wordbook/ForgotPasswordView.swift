//
//  ForgotPasswordView.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct ForgotPasswordView: View {
    @Bindable var store: StoreOf<ForgotPasswordReducer>
    
    var body: some View {
        VStack {
            TextField("Username", text: $store.username)
                .padding(8)
                .background(Color.textBg)
                .cornerRadius(8)
                .padding()
            ProgressView().opacity(store.forgotPasswordCallState.isInProgress ? 1 : 0)
            Button(action: { store.send(.didTapReset) }, label: {
                Text("Reset Password")
            })
            .buttonStyle(ActionButton())
            .disabled(!store.isButtonEnabled)
            .padding()
            Spacer()
        }
        .background(Color.primaryBg)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    ForgotPasswordView(store: Store(initialState: ForgotPasswordReducer.State(), reducer: { ForgotPasswordReducer() }))
}
