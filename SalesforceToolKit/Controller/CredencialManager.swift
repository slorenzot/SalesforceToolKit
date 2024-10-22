//
//  CredencialManager.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 20/08/23.
//

import Foundation

enum EncryptionMethod: String, Encodable, Decodable {
    case AES256 = "AES256"
    case SHA256 = "SHA256"
}

enum LinkType: Encodable, Decodable {
    case Org, Specialized, Toolbox, DevOp, Help, Other
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
                label: "Salesforce (Sandbox)",
                url: "https://test.salesforce.com",
                username: "user",
                password: "pass",
                type: LinkType.Org,
                shortcut: "1"))
        self.add(
            credencial: Link(
                label: "Salesforce (Production)",
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
                type: LinkType.Help,
                shortcut: "7"))
        self.add(
            credencial: Link(
                label: "Salesforce Trailhead",
                url: "https://trailhead.salesforce.com",
                username: "user",
                password: "pass",
                type: LinkType.Help,
                shortcut: "5"))
        
        self.add(
            credencial: Link(
                label: "Workbench",
                url: "https://workbench.developerforce.com/login.php",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "3"))
        self.add(
            credencial: Link(
                label: "JSON2Apex",
                url: "https://json2apex.herokuapp.com",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "4"))
        self.add(
            credencial: Link(
                label: "JSONDiff",
                url: "https://jsonviewer.stack.hu",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "5"))
        
        self.add(
            credencial: Link(
                label: "JSON Viewer",
                url: "https://jsonviewer.stack.hu",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "6"))
        
        self.add(
            credencial: Link(
                label: "Mockaroo",
                url: "https://mockaroo.com",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "7"))
        
        self.add(
            credencial: Link(
                label: "Password generator",
                url: "https://passwordsgenerator.net/",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "7"))
        
        self.add(
            credencial: Link(
                label: "Mocky",
                url: "https://designer.mocky.io/design",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "8"))
        
        self.add(
            credencial: Link(
                label: "Happy Soup",
                url: "https://happysoup.io",
                username: "user",
                password: "pass",
                type: LinkType.Toolbox,
                shortcut: "9"))
        
        self.add(
            credencial: Link(
                label: "Gearset",
                url: "https://app.gearset.com",
                username: "user",
                password: "pass",
                type: LinkType.DevOp,
                shortcut: "9"))
        self.add(
            credencial: Link(
                label: "Copado",
                url: "https://www.copado.com",
                username: "user",
                password: "pass",
                type: LinkType.DevOp,
                shortcut: "9"))
        
        self.add(
            credencial: Link(
                label: "Developer Edition Org",
                url: "https://developer.salesforce.com/signup",
                username: "user",
                password: "pass",
                type: LinkType.Specialized,
                shortcut: "e"))
        
        self.add(
            credencial: Link(
                label: "Financial Services Cloud Org (Trial)",
                url: "https://www.salesforce.com/form/signup/financial-services-cloud-trial/",
                username: "user",
                password: "pass",
                type: LinkType.Specialized,
                shortcut: "e"))
        
        self.add(
            credencial: Link(
                label: "Health Cloud Org (Trial)",
                url: "https://www.salesforce.com/form/signup/health-cloud-trial/",
                username: "user",
                password: "pass",
                type: LinkType.Specialized,
                shortcut: "e"))
        
        self.add(
            credencial: Link(
                label: "Communications Cloud Org (Trial)",
                url: "https://www.salesforce.com/form/signup/comms-cloud-learning-trial/",
                username: "user",
                password: "pass",
                type: LinkType.Specialized,
                shortcut: "e"))
        
        self.add(
            credencial: Link(
                label: "Energy & Utilities Cloud Org (Trial)",
                url: "https://www.salesforce.com/form/industries/energy/energy-utilities-cloud-learning-free-trial/",
                username: "user",
                password: "pass",
                type: LinkType.Specialized,
                shortcut: "e"))
        
        self.add(credencial: Link(
            label: "Partner Org (Using PLC - Require login)",
            url: "https://partnerlearningcamp.salesforce.com/s/demo-org",
            username: "user",
            password: "pass",
            type: LinkType.Specialized,
            shortcut: "p"))
    }
    
    func add(credencial: Link) {
        self.storedLinks.append(credencial)
    }
}
