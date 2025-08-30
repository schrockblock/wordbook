//
//  ResetPasswordView.swift
//  Template
//
//  Created by Elliot Schrock on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct ResetPasswordView: View {
    @Bindable var store: StoreOf<ResetPasswordReducer>
    
    var body: some View {
        VStack {
            SecureField("Password", text: $store.password)
                .padding(8)
                .background(Color.textBg)
                .cornerRadius(8)
                .padding()
            ProgressView().opacity(store.resetPasswordCallState.isInProgress ? 1 : 0)
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
    ResetPasswordView(store: Store(initialState: ResetPasswordReducer.State(), reducer: { ResetPasswordReducer() }))
}
