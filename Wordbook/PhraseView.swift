//
//  PhraseView.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import SwiftUI
import ComposableArchitecture

struct PhraseView: View {
    var phrase: Phrase
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(phrase.id)
            Text(phrase.translation).foregroundColor(.secondary)
        }
    }
}

#Preview {
    PhraseView(phrase: mockPhrases.first!)
}
