//
//  SalesforceToolKitApp.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI
import ServiceManagement

var preferencesWindow: NSWindow?

func openPreferences() {
    if preferencesWindow == nil {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = NSLocalizedString("Preferences", comment: "")
        window.contentView = NSHostingView(rootView: AppPreferencesView())
        preferencesWindow = window
    }
    preferencesWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}


// https://medium.com/@ankit.bhana19/save-custom-objects-into-userdefaults-using-codable-in-swift-5-1-protocol-oriented-approach-ae36175180d8
func toggleLaunchOnLogin() {
    NSApplication.shared.enableRelaunchOnLogin()
}

func openUrl(url: String) {
    // using OAuth token
    // http://[instance].salesforce.com/secur/frontdoor.jsp?sid=[access token]&retURL=[start page]
    // https://sfdcblogger.in/2023/03/09/open-salesforce-org-using-session-id-or-access-token/?i=1
    
    
    if let url = URL(string: url) {
        NSWorkspace.shared.open(url)
    }
}

//func retrieveConfig() {
//    let userDefaults = UserDefaults.standard
//    do {
//        let bookmark = try userDefaults.getObject(forKey: "MyFavouriteBook", castTo: BookMark.self)
//        print(bookmark)
//    } catch {
//        print(error.localizedDescription)
//    }
//}
//
//func saveConfig() {
//    let bookmark = BookMark(label: "asdfs", url: "sdfsd", username: "asdasd", password: "asdasd", shortcut: "asdas")
//    let userDefaults = UserDefaults.standard
//
//    userDefaults.set(bookmark, forKey: "BookMark")
//}

func confirmQuit() {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Confirm exit", comment: "")
    alert.informativeText = NSLocalizedString("Sure?", comment: "")
    alert.addButton(withTitle: NSLocalizedString("Quit", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
    alert.alertStyle = .warning
    
    if (alert.runModal() == .alertFirstButtonReturn) {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct SalesforceToolKitApp: App {
    @AppStorage("relaunchOnLogin") var relaunchOnLogin: Bool = false
    @AppStorage("settings") var settings: String = ""
    
    @State var credentialManager = LinkManager()
    @State var currentOption: String  = "1"
    
    var version = "2.3.0"
    
    var body: some Scene {
        MenuBarExtra(currentOption, systemImage: "cloud.fill") {
            
            Button("Salesforce ToolKit (version \(version))"){}
                .disabled(true)
            Divider()
            
            if (credentialManager.storedLinks.isEmpty) {
                Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
            } else {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.CLI}) { link in
                    Button(link.label){
                        credentialManager.authenticateAndOpenOrg()
                    }
                }
                
                Divider()
                
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Org}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                    // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                }
                
                Divider()
                
                Menu("Request new org") {
                    ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Specialized}) { link in
                        Button(NSLocalizedString("Request", comment: "") + " \(link.label)"){
                            openUrl(url: link.url)
                        }
                        // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                    }
                }
                
                Divider()
                
                Menu("Tools"){
                    ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Toolbox}) { link in
                        Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                            openUrl(url: link.url)
                        }
                        // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                    }
                }
                
                Divider()
                
                Menu("DevOp Tools") {
                    ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.DevOp}) { link in
                        Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                            openUrl(url: link.url)
                        }
                        // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                    }
                }
                
                Divider()
                
                Menu("Help") {
                    ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Help}) { link in
                        Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                            openUrl(url: link.url)
                        }
                        // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                    }
                }
            }
            
            Divider()
            Toggle(NSLocalizedString("Launch at Startup", comment: ""), isOn: $relaunchOnLogin)
                .toggleStyle(.checkbox)
            Button(NSLocalizedString("Preferences", comment: "")) {
                openPreferences()
            }
            .keyboardShortcut("p")
            
            Divider()
            Button(NSLocalizedString("About", comment: "")) {
                openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
            }
            
            Divider()
            Button(NSLocalizedString("Quit", comment: "")) {
                confirmQuit()
            }
            .keyboardShortcut("q")
        }
        
    }
}
