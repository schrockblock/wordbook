//
//  Model.swift
//  Template
//
//  Created by Elliot Schrock on 3/23/24.
//

import Foundation

struct Worterbuch: Codable, Equatable, Identifiable {
    var id: UUID = Current.uuid()
    var name: String
    var key: String
}

struct WorterbuchsWrapper: Codable {
    var wordbooks: [Worterbuch]?
}
