//
//  SalesforceToolKitApp.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI
import ServiceManagement
import UserNotifications


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
    @StateObject var authenticatedOrgManager = AuthenticatedOrgManager()
    @State var currentOption: String  = "1"
    
    @State var preferencesWindow: NSWindow?
    @State var authenticationWindow: NSWindow?
    
    var version = "2.3.0"

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
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

    func openAuthenticationWindow() {
        if authenticationWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false)
            window.center()
            window.title = "Authenticate & Open Org"
            window.contentView = NSHostingView(rootView: AuthenticationView())
            authenticationWindow = window
        }
        authenticationWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func confirmDelete(org: AuthenticatedOrg) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Confirm deletion", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Are you sure you want to delete the org with alias %@?", comment: ""), org.alias)
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            let deleted = authenticatedOrgManager.deleteOrg(org: org)
            
            if (deleted) {
                let content = UNMutableNotificationContent()
                content.title = "Deletion Successful"
                content.body = "Successfully deleted to \(org.alias)."
                content.sound = UNNotificationSound.default

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func openEditAuthenticationWindow(org: AuthenticatedOrg) {
        let editView = EditAuthenticationView(org: org, manager: authenticatedOrgManager)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = "Edit Org"
        window.contentView = NSHostingView(rootView: editView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
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
                        openAuthenticationWindow()
                    }
                }
                
                Menu("Authenticated Orgs") {
                    if authenticatedOrgManager.authenticatedOrgs.isEmpty {
                        Button("No authenticated orgs"){}.disabled(true)
                    } else {
                        ForEach(authenticatedOrgManager.authenticatedOrgs) { org in
                            Menu {
                                Button("Open") {
                                    let cli = SalesforceCLI()
                                    cli.open(alias: org.alias)
                                }
                                Button("Edit") {
                                    openEditAuthenticationWindow(org: org)
                                }
                                Button("Delete") {
                                    confirmDelete(org: org)
                                }
                            } label: {
                                Image(systemName: "cloud.fill")
                                Text("\(org.alias) (\(org.orgType))")
                            }
                        }
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
