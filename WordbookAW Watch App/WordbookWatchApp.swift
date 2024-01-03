//
//  WordbookWatchApp.swift
//  WordbookAW Watch App
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct WordbookWatchApp: App {
    var body: some Scene {
        WindowGroup {
            PhrasesView(store: Store(initialState: PhrasesReducer.State(), reducer: { PhrasesReducer() }))
        }
    }
}
