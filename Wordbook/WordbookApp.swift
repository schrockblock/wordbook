//
//  WordbookApp.swift
//  Wordbook
//
//  Created by Elliot Schrock on 9/21/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct WordbookApp: App {
    var body: some Scene {
        WindowGroup {
            //SplashView(store: Store(initialState: SplashReducer.State(), reducer: { SplashReducer()._printChanges() }))
//            PhrasesView(store: Store(initialState: PhrasesReducer.State(), reducer: { PhrasesReducer()._printChanges() }))
            AddableListView(title: "Phrases",
                            store: Store(initialState: AddableListReducer.State(phraseToItemState: { $0 },                                                                     phraseToSearchableString: { "\($0.id) \($0.translation)" }), reducer: { AddableListReducer() }),
                            rowContent: PhraseView.init,
                            detailsContent: PhraseView.init,
                            addContent: EditPhraseView.init,
                            editContent: EditPhraseView.init)
        }
    }
}

public extension Color {
    static let primaryBg = Color(red: 0x8F / 0xFF, green: 0x3F / 0xFF, blue: 0x6A / 0xFF)
    static let textBg = Color.white
    static let accentButton = Color.white
    static let buttonText = Color(red: 0x82 / 0xFF, green: 0xAC / 0xFF, blue: 0x38 / 0xFF)
}

struct ActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentButton)
            .foregroundStyle(Color.buttonText)
            .clipShape(Capsule())
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color.white)
            .overlay {
                Capsule()
                        .stroke(.white, lineWidth: 1)
            }
    }
}
