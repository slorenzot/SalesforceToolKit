//
//  SalesforceToolKitApp.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI
import ServiceManagement // Add this import for SMAppService
import UserNotifications
import LocalAuthentication // Add this import for Touch ID/Face ID

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

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, NSWindowDelegate {
    var window: NSWindow!
    
    static let windowWillCloseNotification = Notification.Name("windowWillCloseNotification")
    
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
    
    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: AppDelegate.windowWillCloseNotification, object: notification.object)
    }
}

@main
struct SalesforceToolKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("settings") var settings: String = ""
    // New AppStorage for biometric authentication setting
    @AppStorage("biometricAuthenticationEnabled") var biometricAuthenticationEnabled: Bool = false
    
    @State var credentialManager = LinkManager()
    @StateObject var authenticatedOrgManager = AuthenticatedOrgManager()
    @StateObject private var keyMonitor = KeyMonitor()
    // New StateObject for the local authentication manager
    @StateObject private var authManager = LocalAuthenticationManager()
    @State var currentOption: String  = "1"
    
    @State var preferencesWindow: NSWindow?
    @State var authenticationWindow: NSWindow?
    @State var mainWindow: NSWindow?
    @State var editAuthenticationWindow: NSWindow?
    @State var viewOrganizationDetailsWindow: NSWindow?

    @State private var launchOnLogin = false

    private func setLaunchOnLogin(enabled: Bool) async { // MARK: - Changed to async
        let serviceIdentifier = "com.nesponsoul.SalesforceToolKit-Launcher"
        let content = UNMutableNotificationContent()
        
        let service = SMAppService.loginItem(identifier: serviceIdentifier)
        
        do {
            if enabled {
                try service.register()
                content.title = "Agregado al inicio exitoso"
                content.body = "Se ha añadido como elemento en el inicio."
                content.sound = UNNotificationSound.default
            } else {
                try await service.unregister()
                content.title = "Eliminado en el inicio exitoso"
                content.body = "Se ha removido de los elemento en el inicio."
                content.sound = UNNotificationSound.default
            }
        } catch {
            print("Failed to set login item: \(error)")
            content.title = "Error al configurar inicio"
            content.body = "Hubo un error al \(enabled ? "añadir" : "remover") como elemento de inicio: \(error.localizedDescription)"
            content.sound = UNNotificationSound.default
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error decoding org details: \(error)")
        }
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
    
    private func onWindowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window == mainWindow {
            mainWindow = nil
        } else if window == preferencesWindow {
            preferencesWindow = nil
        } else if window == authenticationWindow {
            authenticationWindow = nil
        } else if window == editAuthenticationWindow {
            editAuthenticationWindow = nil
        } else if window == viewOrganizationDetailsWindow {
            viewOrganizationDetailsWindow = nil
        }
    }
    
    // MARK: - Biometric Authentication Helper
    /// Authenticates the user with biometrics if enabled and available, then executes the action.
    /// If authentication fails or is not required, an alert is shown or the action is executed directly.
    private func authenticateIfRequired(reason: String, action: @escaping () -> Void) {
        if biometricAuthenticationEnabled && authManager.isTouchIDAvailable {
            authManager.authenticate(reason: reason) { success in
                if success {
                    action()
                } else {
                    // Show an alert if authentication fails
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Authentication Failed", comment: "")
                    alert.informativeText = NSLocalizedString("Could not verify your identity. Access denied.", comment: "")
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        } else {
            action() // Execute immediately if biometrics are not enabled or not available
        }
    }
    
    func openPreferences() {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to open preference window", comment: "")) {
            if preferencesWindow == nil {
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 120),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false)
                window.center()
                window.title = NSLocalizedString("Preferences", comment: "")
                // Pass the biometric settings to AppPreferencesView
                window.contentView = NSHostingView(rootView: AppPreferencesView(
                    biometricAuthenticationEnabled: $biometricAuthenticationEnabled,
                    isTouchIDAvailable: authManager.isTouchIDAvailable
                ))
                window.isReleasedWhenClosed = false
                preferencesWindow = window
                window.delegate = appDelegate
            }
            preferencesWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func exportPreferences() {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to export organization data", comment: "")) {
            let savePanel = NSSavePanel()
            savePanel.allowedFileTypes = ["json"]
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = "sftk-preferences.json"
            savePanel.prompt = NSLocalizedString("Export", comment: "")
            savePanel.title = NSLocalizedString("Export Salesforce Organizations", comment: "")

            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        // Assuming authenticatedOrgManager has an accessible array of AuthenticatedOrg
                        // You need to ensure AuthenticatedOrgManager exposes this data,
                        // for example, via a property like 'authenticatedOrgs'.
                        let organizationsToExport = self.authenticatedOrgManager.authenticatedOrgs

                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted // For human-readable JSON

                        let jsonData = try encoder.encode(organizationsToExport)
                        try jsonData.write(to: url, options: .atomicWrite)

                        let content = UNMutableNotificationContent()
                        content.title = NSLocalizedString("Export Successful", comment: "")
                        content.body = String(format: NSLocalizedString("Organization data exported to %@", comment: ""), url.lastPathComponent)
                        content.sound = UNNotificationSound.default
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)

                    } catch {
                        print("Failed to export organization data: \(error)")
                        let content = UNMutableNotificationContent()
                        content.title = NSLocalizedString("Export Failed", comment: "")
                        content.body = String(format: NSLocalizedString("Error exporting organization data: %@", comment: ""), error.localizedDescription)
                        content.sound = UNNotificationSound.default
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    func importPreferences() {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to import organization data", comment: "")) {
            let openPanel = NSOpenPanel()
            openPanel.allowedFileTypes = ["json"]
            openPanel.canChooseDirectories = false
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.prompt = NSLocalizedString("Importar", comment: "")
            openPanel.title = NSLocalizedString("Importar Organizaciones de Salesforce", comment: "")

            openPanel.begin { response in
                if response == .OK, let url = openPanel.url {
                    do {
                        let jsonData = try Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        let importedOrgs = try decoder.decode([AuthenticatedOrg].self, from: jsonData)
                        
                        // Use the new importOrgs method in AuthenticatedOrgManager
                        self.authenticatedOrgManager.importOrgs(newOrgs: importedOrgs)

                    } catch {
                        print("Failed to import organization data: \(error)")
                        let content = UNMutableNotificationContent()
                        content.title = NSLocalizedString("Importación Fallida", comment: "")
                        content.body = String(format: NSLocalizedString("Error al importar datos de la organización: %@", comment: ""), error.localizedDescription)
                        content.sound = UNNotificationSound.default
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }
    
    func openMainWindow() {
        if mainWindow == nil {
            let editView = MainView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 450),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false)
            window.center()
            window.title = "Salesforce Toolkit"
            window.contentView = NSHostingView(rootView: editView)
            window.isReleasedWhenClosed = false
            mainWindow = window
            window.delegate = appDelegate
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func openAuthenticationWindow() {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to open authentication window", comment: "")) {
            if authenticationWindow == nil {
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false)
                window.center()
                window.title = "Autenticar y Abrir Organización"
                window.contentView = NSHostingView(rootView: OrgAuthenticationView().environmentObject(authenticatedOrgManager))
                window.isReleasedWhenClosed = false
                authenticationWindow = window
                window.delegate = appDelegate
            }
            authenticationWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func confirmLogout(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to logout from an organization", comment: "")) {
            let alert = NSAlert()
            alert.messageText = "Confirmar cerrar sesión"
            alert.informativeText = "¿Esta seguro que desea cerrar la sesión con la instancia \(org.label) (\(org.label))?"
                + "\n\n"
                + "Se cerrarán todas las conexiones con la instancia."
            alert.addButton(withTitle: NSLocalizedString("Si, cerrar sesión", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancelar", comment: ""))
            alert.alertStyle = .warning

            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                let logout = cli.logout(alias: org.alias)
                let deleted = authenticatedOrgManager.deleteOrg(org: org)
                
                if (logout) {
                    if (deleted) {
                        let content = UNMutableNotificationContent()
                        content.title = "Cierre de sesión exitoso"
                        content.body = "Se ha cerrado existosamente la sesión en la instancia \(org.label) (\(org.alias))."
                        content.sound = UNNotificationSound.default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    func confirmDelete(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to delete an organization", comment: "")) {
            let alert = NSAlert()
            alert.messageText = "Confirmar borrado"
            alert.informativeText = "¿Esta seguro que desea cerrar la sesión con la instancia \(org.label) (\(org.label)?"
            + "\n\n"
            + "Antes de eliminar la sesión se cerrarán todas las conexiones con la instancia."
            alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancelar", comment: ""))
            alert.alertStyle = .warning

            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                let logout = cli.logout(alias: org.alias)
                let deleted = authenticatedOrgManager.deleteOrg(org: org)
               
                if (logout) {
                    if (deleted) {
                        let content = UNMutableNotificationContent()
                        content.title = "Eliminación exitosa"
                        content.body = "Se ha eliminado exitosamente la organización \(org.label) (\(org.alias))."
                        content.sound = UNNotificationSound.default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    func openEditAuthenticationWindow(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to edit organization details", comment: "")) {
            if editAuthenticationWindow == nil {
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false)
                window.center()
                window.title = "Editar \(org.label)"
                window.isReleasedWhenClosed = false
                editAuthenticationWindow = window
                window.delegate = appDelegate
            }
            
            let editView = OrgAuthenticationView(org: org)
            editAuthenticationWindow?.contentView = NSHostingView(rootView: editView.environmentObject(authenticatedOrgManager))
            editAuthenticationWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func viewOrganizationDetailsWindow(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to view organization details", comment: "")) {
            if viewOrganizationDetailsWindow == nil {
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                    styleMask: [.titled, .closable],
                    backing: .buffered,
                    defer: false)
                window.center()
                // The title "Edit Org" here seems like a typo if this is for viewing details.
                // You might want to change it to "View \(org.label) Details" or similar.
                window.title = "Detalles de la Organización"
                window.isReleasedWhenClosed = false
                viewOrganizationDetailsWindow = window
                window.delegate = appDelegate
            }
            
            // Reusing AuthenticationView for viewing might not be ideal if it allows editing.
            // Consider creating a dedicated `ViewOrganizationDetailsView` if you only want to display.
            let detailsView = OrgDetailsView(org: org)
            viewOrganizationDetailsWindow?.contentView = NSHostingView(rootView: detailsView.environmentObject(authenticatedOrgManager))
            viewOrganizationDetailsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    var body: some Scene {
        MenuBarExtra(currentOption, systemImage: "key.fill") {
            MenuBarContentView(
                keyMonitor: keyMonitor,
                authenticatedOrgManager: authenticatedOrgManager,
                launchOnLogin: $launchOnLogin,
                setLaunchOnLogin: { enabled in
                    // Call the async function from a Task
                    Task {
                        await setLaunchOnLogin(enabled: enabled)
                    }
                },
                credentialManager: credentialManager,
                version: version,
                mainWindow: openMainWindow,
                // Fix for the error: explicitly wrap authenticateIfRequired in a closure
                // to match the expected labeled parameter type.
                authenticateIfRequired: { reason, action in
                    self.authenticateIfRequired(reason: reason, action: action)
                },
                openAuthenticationWindow: openAuthenticationWindow,
                openEditAuthenticationWindow: openEditAuthenticationWindow,
                viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                confirmDelete: confirmDelete,
                confirmLogout: confirmLogout,
                openPreferences: openPreferences,
                exportPreference: exportPreferences,
                importPreference: importPreferences, // Add this line
                confirmQuit: confirmQuit,
                // Pass new biometric authentication parameters to MenuBarContentView
                biometricAuthenticationEnabled: $biometricAuthenticationEnabled,
                isTouchIDAvailable: authManager.isTouchIDAvailable
            )
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.windowWillCloseNotification)) { notification in
                self.onWindowWillClose(notification)
            }
        }
        
        // Define the window that will be shown on icon click
        WindowGroup("My Custom Window", id: "myCustomWindow") {
            MainView()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "openMyWindow")) // For programmatic opening
        
    }
}

