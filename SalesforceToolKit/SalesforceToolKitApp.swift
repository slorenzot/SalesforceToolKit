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
    alert.messageText = "Confirm exit"
    alert.informativeText = "Sure?"
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .warning
    
    if (alert.runModal() == .alertFirstButtonReturn) {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct SalesforceToolKitApp: App {
    @AppStorage("relaunchOnLogin") var relaunchOnLogin: Bool = false
    @AppStorage("settings") var settings: String = ""
    
    @State var credentialManager = OrgManager()
    @State var currentOption: String  = "1"
    
    var version = "1.0.1"
    
    var body: some Scene {
        MenuBarExtra(currentOption, systemImage: "cloud.fill") {
            Button("Open Salesforce Org Manager"){}
                .keyboardShortcut("o")
                .disabled(true)
            Divider()
            
            if (credentialManager.storedOrgs.isEmpty) {
                Button("No stored credentials..."){}.disabled(true)
            } else {
                ForEach(credentialManager.storedOrgs) { credencial in
                    Button("Open \(credencial.label)"){
                        openUrl(url: credencial.url)
                    }
                }
            }
            
            Divider()
            Toggle("Launch at Startup", isOn: $relaunchOnLogin)
                .toggleStyle(.checkbox)
            Button("Preferences") {
                openPreferences()
            }
            .keyboardShortcut("p")
            .disabled(true)
            
            Divider()
            Button("Credits (version \(version))") {
                openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
            }
            
            Divider()
            Button("Quit") {
                confirmQuit()
            }
            .keyboardShortcut("q")
        }
        
    }
}
