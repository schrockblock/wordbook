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
            WorterbuchListView(
                title: "Wordbooks",
                store: Store(
                    initialState: WorterbuchListReducer.State(
                        worterbuchToItemState: { WorterbuchItemReducer.State(worterbuch: $0) },
                        worterbuchToSearchableString: { $0.name }
                    ),
                    reducer: { WorterbuchListReducer() }
                )
            )
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
