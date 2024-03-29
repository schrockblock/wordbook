//
//  Phrase.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import Foundation

public struct Phrase: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let translation: String?
    public let createdAt: Date
    
    public init(id: String, translation: String?, createdAt: Date) {
        self.id = id
        self.translation = translation
        self.createdAt = createdAt
    }
}

public let mockPhrases = [Phrase(id: "die Waesche zusammen legen", translation: "fold the laundry", createdAt: Date(timeIntervalSinceNow: -3.0)), Phrase(id: "aufregend", translation: "exciting", createdAt: Date(timeIntervalSinceNow: -2.0))]
