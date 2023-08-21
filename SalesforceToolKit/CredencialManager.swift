//
//  CredencialManager.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 20/08/23.
//

import Foundation

enum OrgType: Encodable, Decodable {
    case Production, Sandbox, Other
}

final class OrgCredencial: Identifiable {
    var label: String
    var url: String
    var username: String
    var password: String
    var type: OrgType? = OrgType.Sandbox
    var shortcut: String
    
    init(label: String, url: String, username: String, password: String, type: OrgType, shortcut: String) {
        self.label = label
        self.url = url
        self.username = username
        self.password = password
        self.type = type
        self.shortcut = shortcut
    }
}

class OrgManager: ObservableObject {
    @Published var storedOrgs : [OrgCredencial] = []
    
    init() {
        self.add(
            credencial: OrgCredencial(
                label: "Salesforce login (Sandbox)",
                url: "https://test.salesforce.com",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "1"))
        self.add(
            credencial: OrgCredencial(
                label: "Salesforce login (Production)",
                url: "https://login.salesforce.com",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "2"))
        self.add(
            credencial: OrgCredencial(
                label: "Salesforce Help",
                url: "https://help.salesforce.com/s/",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "7"))
        self.add(
            credencial: OrgCredencial(
                label: "Salesforce Trailhead website",
                url: "https://trailhead.salesforce.com",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "5"))
        
        self.add(
            credencial: OrgCredencial(
                label: "Workbench Tool",
                url: "https://workbench.developerforce.com/login.php",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "3"))
        self.add(
            credencial: OrgCredencial(
                label: "JSON2Apex Tool",
                url: "https://json2apex.herokuapp.com",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "4"))
        
        self.add(
            credencial: OrgCredencial(
                label: "Online JSON Viewer",
                url: "https://jsonviewer.stack.hu",
                username: "user",
                password: "pass",
                type: OrgType.Sandbox,
                shortcut: "6"))
    
    }
    
    func add(credencial: OrgCredencial) {
        self.storedOrgs.append(credencial)
    }
}
