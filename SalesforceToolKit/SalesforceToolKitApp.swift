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


func openUrl(url: String) -> Bool {
    // using OAuth token
    // http://[instance].salesforce.com/secur/frontdoor.jsp?sid=[access token]&retURL=[start page]
    // https://sfdcblogger.in/2023/03/09/open-salesforce-org-using-session-id-or-access-token/?i=1
    
    if let url = URL(string: url) {
        NSWorkspace.shared.open(url)
    }
    
    return true
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

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        if runningApps.count > 1 {
            print("Another instance is already running. Activating it and terminating.")
            runningApps.first?.activate(options: .activateIgnoringOtherApps)
            NSApp.terminate(nil)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
}

@main
struct SalesforceToolKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("settings") var settings: String = ""
    
    @State var credentialManager = LinkManager()
    @StateObject var authenticatedOrgManager = AuthenticatedOrgManager()
    @StateObject private var keyMonitor = KeyMonitor()
    @State var currentOption: String  = "1"
    
    @State var preferencesWindow: NSWindow?
    @State var authenticationWindow: NSWindow?
    
    @State private var launchOnLogin = false

    private func setLaunchOnLogin(enabled: Bool) {
        let identifier = "com.nesponsoul.SalesforceToolKit-Launcher" as CFString
        SMLoginItemSetEnabled(identifier, enabled)
    }
    
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
            window.title = "Autenticar y Abrir Organización"
            window.contentView = NSHostingView(rootView: AuthenticationView().environmentObject(authenticatedOrgManager))
            authenticationWindow = window
        }
        authenticationWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func confirmLogout(org: AuthenticatedOrg) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Confirm logout", comment: "")
        alert.informativeText = String(format: NSLocalizedString("Are you sure you want to logout the org with alias %@?", comment: ""), org.alias)
        alert.addButton(withTitle: NSLocalizedString("Logout", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            let deleted = authenticatedOrgManager.deleteOrg(org: org)
            
            if (deleted) {
                let content = UNMutableNotificationContent()
                content.title = "Logout Successful"
                content.body = "Successfully logout to \(org.alias)."
                content.sound = UNNotificationSound.default

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        }
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
                content.title = "Eliminación exitosa"
                content.body = "Se ha eliminado exitosamente la organización \(org.label) (\(org.alias)."
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
        window.title = "Editar organización"
        window.contentView = NSHostingView(rootView: editView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func viewOrganizationDetailsWindow(org: AuthenticatedOrg) {
        let cli = SalesforceCLI()
        let details = cli.orgDetails(alias: org.alias)
        // print("\(details?.clientId ??)")
        
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
        MenuBarExtra(currentOption, systemImage: "key.icloud.fill") {
            MenuBarContentView(
                keyMonitor: keyMonitor,
                authenticatedOrgManager: authenticatedOrgManager,
                launchOnLogin: $launchOnLogin,
                setLaunchOnLogin: setLaunchOnLogin,
                credentialManager: credentialManager,
                version: version,
                openAuthenticationWindow: openAuthenticationWindow,
                openEditAuthenticationWindow: openEditAuthenticationWindow,
                viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                confirmDelete: confirmDelete,
                confirmLogout: confirmLogout,
                openPreferences: openPreferences,
                confirmQuit: confirmQuit
            )
        }
        
    }
}
