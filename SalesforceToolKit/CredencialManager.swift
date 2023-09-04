//
//  CredencialManager.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 20/08/23.
//

import Foundation

enum LinkType: Encodable, Decodable {
    case Org, Toolbox, Other
}

final class Link: Identifiable {
    var label: String
    var url: String
    var username: String
    var password: String
    var type: LinkType? = LinkType.Org
    var shortcut: String
    
    init(label: String, url: String, username: String, password: String, type: LinkType, shortcut: String) {
        self.label = label
        self.url = url
        self.username = username
        self.password = password
        self.type = type
        self.shortcut = shortcut
    }
}

class LinkManager: ObservableObject {
    @Published var storedLinks : [Link] = []
    
    init() {
        self.add(
            credencial: Link(
                label: "Salesforce login (Sandbox)",
                url: "https://test.salesforce.com",
                username: "user",
                password: "pass",
                type: LinkType.Org,
                shortcut: "1"))
        self.add(
            credencial: Link(
                label: "Salesforce login (Production)",
                url: "https://login.salesforce.com",
                username: "user",
                password: "pass",
                type: LinkType.Org,
                shortcut: "2"))
        self.add(
            credencial: Link(
                label: "Salesforce Help",
                url: "https://help.salesforce.com/s/",
                username: "user",
                password: "pass",
                type: LinkType.Other,
                shortcut: "7"))
        self.add(
            credencial: Link(
                label: "Salesforce Trailhead website",
                url: "https://trailhead.salesforce.com",
                username: "user",
                password: "pass",
                type: LinkType.Other,
                shortcut: "5"))
        
        self.add(
            credencial: Link(
                label: "Workbench Tool",
                url: "https://workbench.developerforce.com/login.php",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "3"))
        self.add(
            credencial: Link(
                label: "JSON2Apex Tool",
                url: "https://json2apex.herokuapp.com",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "4"))
        
        self.add(
            credencial: Link(
                label: "Online JSON Viewer",
                url: "https://jsonviewer.stack.hu",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "6"))
        
        self.add(
            credencial: Link(
                label: "Online Mockaroo",
                url: "https://mockaroo.com",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "7"))
        
    }
    
    func add(credencial: Link) {
        self.storedLinks.append(credencial)
    }
}
