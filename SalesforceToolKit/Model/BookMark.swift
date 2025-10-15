//
//  BookMark.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 15/10/24.
//

struct BookMark: Codable {
    var label: String
    var url: String
    var username: String
    var password: String
    var type: LinkType? = LinkType.Org
    var shortcut: String
    var encryptionMethod: EncryptionMethod? = EncryptionMethod.AES256
}
