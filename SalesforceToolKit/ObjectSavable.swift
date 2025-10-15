//
//  ObjectSavable.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 15/10/24.
//


protocol ObjectSavable {
    func setObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable
    func getObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable
}