//
//  SalesforceToolKitApp.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI
import ServiceManagement

//class AppPreferences: NSWindow {
//    init() {
//        super.init(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
//        makeKeyAndOrderFront(nil)
//        isReleasedWhenClosed = false
//        styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
//        title = "title placeholder"
//        contentView = NSHostingView(rootView: ContentView())
//    }
//}

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

func openPreferences() {
    CreditsView()
}

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
    
    var version = "2.1.1"
    
    var body: some Scene {
        MenuBarExtra(currentOption, systemImage: "cloud.fill") {
            Button("Salesforce ToolKit (version \(version))"){}
                .disabled(true)
            Divider()
            
            if (credentialManager.storedLinks.isEmpty) {
                Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
            } else {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Org}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                    // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                }
                
                Divider()
                
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Toolbox}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                    // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                }
                
                Divider()
                
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.DevOp}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                    // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                }
                
                Divider()
                
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Other}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                    // TODO: agregar icono dependiento del tipo de Enlace en LinkType
                }
            }
            
            Divider()
            Toggle(NSLocalizedString("Launch at Startup", comment: ""), isOn: $relaunchOnLogin)
                .toggleStyle(.checkbox)
            Button(NSLocalizedString("Preferences", comment: "")) {
                openPreferences()
            }
            .keyboardShortcut("p")
            .disabled(true)
            
            //            Divider()
            //            Button("Credits (version \(version))") {
            //                openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
            //            }
            
            Divider()
            Button(NSLocalizedString("Quit", comment: "")) {
                confirmQuit()
            }
            .keyboardShortcut("q")
        }
        
    }
}
