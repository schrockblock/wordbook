//
//  Model.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import Foundation

struct Worterbuch: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var key: String
    var targetLanguage: Language

    init(id: UUID = UUID(), name: String, key: String, targetLanguage: Language = .german) {
        self.id = id
        self.name = name
        self.key = key
        self.targetLanguage = targetLanguage
    }

    enum CodingKeys: String, CodingKey {
        case id, name, key, targetLanguage
    }

    // Custom decoder so existing installs whose persisted Worterbuchs predate
    // the `targetLanguage` field still decode — they fall back to .german,
    // which matches the app's prior hardcoded German↔English behavior.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.key = try c.decode(String.self, forKey: .key)
        self.targetLanguage = try c.decodeIfPresent(Language.self, forKey: .targetLanguage) ?? .german
    }
}

struct WorterbuchsWrapper: Codable {
    var wordbooks: [Worterbuch]?
}

let worterbuchsKey = "wordbooks"

// Loads persisted Worterbuchs. If none are persisted but legacy phrases exist
// at the default "phrases" key (from a pre-language-pair install), seed a
// "Default" German↔English wordbook pointing at that key so the user's
// existing translations are immediately visible after upgrade.
func loadWorterbuchs() -> [Worterbuch] {
    if let data = UserDefaults.standard.data(forKey: worterbuchsKey),
       let buchs = try? JSONDecoder().decode([Worterbuch].self, from: data) {
        return buchs
    }
    if !loadData("phrases").isEmpty {
        return [Worterbuch(name: "Default", key: "phrases", targetLanguage: .german)]
    }
    return []
}

func saveWorterbuchs(_ buchs: [Worterbuch]) {
    try? UserDefaults.standard.set(JSONEncoder().encode(buchs), forKey: worterbuchsKey)
}
