//
//  User.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/23/24.
//

import Foundation
public struct User: Codable {
    var username: String?
    var email: String?
    var password: String?
    
    var apiKey: String?
    
    var givenName: String?
    var familyName: String?
    
    var phoneNumber: String?
}
