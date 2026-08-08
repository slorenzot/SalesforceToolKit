//
//  SalesforceToolKitApp.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI
import ServiceManagement
import UserNotifications
import LocalAuthentication

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

    // MARK: - Handle notification actions (e.g., update available)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // User tapped the notification body
            if let updateURLString = response.notification.request.content.userInfo["updateURL"] as? String,
               let url = URL(string: updateURLString) {
                NSWorkspace.shared.open(url)
            }
        }
        completionHandler()
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

// MARK: - GitHub Release Model for Update Check
struct GitHubRelease: Decodable {
    let tagName: String
    let htmlUrl: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

private enum WindowID {
    static let main = "main"
    static let preferences = "preferences"
    static let authentication = "authentication"
    static let editAuthentication = "edit-authentication"
    static let organizationDetails = "organization-details"
    static let objectPrompt = "object-prompt"
    static let cliUpdate = "cli-update"
}

@main
struct SalesforceToolKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    @AppStorage("version") var appIsUpdated: Bool = true
    @AppStorage("settings") var settings: String = ""
    // New AppStorage for biometric authentication setting
    @AppStorage("biometricAuthenticationEnabled") var biometricAuthenticationEnabled: Bool = false
    
    @State var credentialManager = LinkManager()
    @StateObject var authenticatedOrgManager = AuthenticatedOrgManager()
    @StateObject private var keyMonitor = KeyMonitor()
    // New StateObject for the local authentication manager
    @StateObject private var authManager = LocalAuthenticationManager()
    @State var currentOption: String  = "1"
    
    @State private var organizationForEditing: AuthenticatedOrg?
    @State private var organizationForDetails: AuthenticatedOrg?
    @State private var organizationForObjectPrompt: AuthenticatedOrg?
    @AppStorage("defaultBrowser") private var defaultBrowser: String = "chrome"

    @State private var launchOnLogin = false

    private func setLaunchOnLogin(enabled: Bool) async {
        // Para registrar la aplicación principal como un elemento de inicio,
        // debes usar SMAppService.mainApp en lugar de SMAppService.loginItem(identifier:).
        let service = SMAppService.mainApp
        let content = UNMutableNotificationContent()
        
        do {
            if enabled {
                try service.register()
                content.title = localized("Startup item added")
                content.body = localized("The application was added to your login items.")
                content.sound = UNNotificationSound.default
            } else {
                try await service.unregister()
                content.title = localized("Startup item removed")
                content.body = localized("The application was removed from your login items.")
                content.sound = UNNotificationSound.default
            }
        } catch {
            print("Failed to set login item: \(error)")
            content.title = localized("Startup configuration failed")
            content.body = localized("Could not %@ the application as a login item: %@", enabled ? localized("add") : localized("remove"), error.localizedDescription)
            content.sound = UNNotificationSound.default
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error adding notification: \(error)") // Corrected print statement
        }
    }
    
    // Computed property to get the app version from Info.plist
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
        
        // Start the update check task when the app initializes
        Task { [self] in // Explicitly capture self
            await checkForUpdates()
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
            openWindow(id: WindowID.preferences)
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
        openWindow(id: WindowID.main)
    }
    
    func openAuthenticationWindow() {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to open authentication window", comment: "")) {
            openWindow(id: WindowID.authentication)
        }
    }
    
    func confirmLogout(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to logout from an organization", comment: "")) {
            let alert = NSAlert()
            alert.messageText = localized("Confirm sign out")
            alert.informativeText = localized("Are you sure you want to sign out of %@ (%@)?", org.label, org.alias)
                + "\n\n"
                + "Se cerrarán todas las conexiones con la instancia."
            alert.addButton(withTitle: localized("Sign out"))
            alert.addButton(withTitle: localized("Cancel"))
            alert.alertStyle = .warning

            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                let logout = cli.logout(alias: org.alias)
                let deleted = authenticatedOrgManager.deleteOrg(org: org)
                
                if (logout) {
                    if (deleted) {
                        let content = UNMutableNotificationContent()
                        content.title = localized("Sign out successful")
                        content.body = localized("You successfully signed out of %@ (%@).", org.label, org.alias)
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
            alert.messageText = localized("Confirm deletion")
            alert.informativeText = localized("Are you sure you want to delete %@ (%@)?", org.label, org.alias)
            + "\n\n"
            + "Antes de eliminar la sesión se cerrarán todas las conexiones con la instancia."
            alert.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
            alert.addButton(withTitle: localized("Cancel"))
            alert.alertStyle = .warning

            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                let logout = cli.logout(alias: org.alias)
                let deleted = authenticatedOrgManager.deleteOrg(org: org)
               
                if (logout) {
                    if (deleted) {
                        let content = UNMutableNotificationContent()
                        content.title = localized("Deletion successful")
                        content.body = localized("The organization %@ (%@) was deleted successfully.", org.label, org.alias)
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
            organizationForEditing = org
            openWindow(id: WindowID.editAuthentication)
        }
    }
    
    func viewOrganizationDetailsWindow(org: AuthenticatedOrg) {
        authenticateIfRequired(reason: NSLocalizedString("Authenticate to view organization details", comment: "")) {
            organizationForDetails = org
            openWindow(id: WindowID.organizationDetails)
        }
    }

    func openObjectPromptWindow(org: AuthenticatedOrg) {
        organizationForObjectPrompt = org
        openWindow(id: WindowID.objectPrompt)
    }

    private func openObject(organization: AuthenticatedOrg, objectId: String) {
        authenticateIfRequired(reason: localized("Authenticate to open object")) {
            let currentCLI = SalesforceCLI()
            let alias = organization.alias
            let browser = organization.useBrowser ?? defaultBrowser
            let path = "/lightning/r/\(objectId)/view"

            Task.detached {
                if currentCLI.isOutdated() {
                    await MainActor.run {
                        notifySalesforceNotOutdated()
                    }
                    return
                }

                let success = currentCLI.open(alias: alias, path: path, browser: browser)

                if !success {
                    await MainActor.run {
                        let content = UNMutableNotificationContent()
                        content.title = localized("Opening object failed")
                        content.body = localized("Salesforce CLI could not open the requested object.")
                        content.sound = UNNotificationSound.default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    // MARK: - Update Check Functionality
    private func checkForUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/slorenzot/SalesforceToolKit/releases/latest") else {
            print("Invalid GitHub API URL for update check.")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let latestRelease = try decoder.decode(GitHubRelease.self, from: data)

            // Get current app version from Info.plist
            let currentAppVersion = self.appVersion
            
            print("current: \(currentAppVersion), latest: \(latestRelease.tagName)")

            // Compare versions numerically
            // .orderedDescending means latestRelease.tagName is newer than currentAppVersion
            if latestRelease.tagName.compare(currentAppVersion, options: .numeric) == .orderedDescending {
                appIsUpdated = false
                
                // New version available
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("Nueva actualización disponible", comment: "Notification title for new app version")
                content.body = String(format: NSLocalizedString("La versión %@ de la aplicación está disponible. Actualmente tienes la versión %@. Haz clic para descargar.", comment: "Notification body for new app version, with versions"), latestRelease.tagName, currentAppVersion)
                content.sound = UNNotificationSound.default
                content.userInfo = ["updateURL": latestRelease.htmlUrl.absoluteString] // Pass URL to notification delegate

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                try await UNUserNotificationCenter.current().add(request)
            } else {
                appIsUpdated = true
                print("App is up to date: \(currentAppVersion)")
            }

        } catch {
            print("Error checking for updates: \(error.localizedDescription)")
            // Optionally, you might want to show a subtle in-app message or log the error,
            // but not typically a critical alert for a failed update check.
        }
    }
    
    var body: some Scene {
        MenuBarExtra(currentOption, systemImage: "cloud.fill") {
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
                version: appVersion, // Use the computed property for consistency
                mainWindow: openMainWindow,
                // Fix for the error: explicitly wrap authenticateIfRequired in a closure
                // to match the expected labeled parameter type.
                authenticateIfRequired: { reason, action in
                    self.authenticateIfRequired(reason: reason, action: action)
                },
                openAuthenticationWindow: openAuthenticationWindow,
                openObjectPromptWindow: openObjectPromptWindow,
                openEditAuthenticationWindow: openEditAuthenticationWindow,
                viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                confirmDelete: confirmDelete,
                confirmLogout: confirmLogout,
                openPreferences: openPreferences,
                exportPreference: exportPreferences,
                importPreference: importPreferences, // Add this line
                confirmQuit: confirmQuit,
                openCLIUpdateWindow: { openWindow(id: WindowID.cliUpdate) },
                // Pass new biometric authentication parameters to MenuBarContentView
                biometricAuthenticationEnabled: $biometricAuthenticationEnabled,
                isTouchIDAvailable: authManager.isTouchIDAvailable,
                appIsUpdated: appIsUpdated
            )
        }
        
        WindowGroup(Text(localized("Salesforce Toolkit")), id: WindowID.main) {
            MainView()
                .environmentObject(authenticatedOrgManager)
        }
        .defaultSize(width: 700, height: 450)

        Window(Text(localized("Preferences")), id: WindowID.preferences) {
            AppPreferencesView(
                biometricAuthenticationEnabled: $biometricAuthenticationEnabled,
                isTouchIDAvailable: authManager.isTouchIDAvailable
            )
        }
        .defaultSize(width: 520, height: 480)

        Window(Text(localized("Update Salesforce CLI")), id: WindowID.cliUpdate) {
            CLIUpdateView()
        }
        .defaultSize(width: 360, height: 190)

        Window(Text(localized("Authenticate and open organization")), id: WindowID.authentication) {
            OrgAuthenticationView()
                .environmentObject(authenticatedOrgManager)
        }
        .defaultSize(width: 480, height: 520)

        Window(Text(localized("Edit organization")), id: WindowID.editAuthentication) {
            if let organizationForEditing {
                OrgAuthenticationView(org: organizationForEditing)
                    .environmentObject(authenticatedOrgManager)
            } else {
                Text(localized("No organization selected"))
            }
        }
        .defaultSize(width: 480, height: 520)

        Window(Text(localized("Organization details")), id: WindowID.organizationDetails) {
            if let organizationForDetails {
                OrgDetailsView(org: organizationForDetails)
                    .environmentObject(authenticatedOrgManager)
            } else {
                Text(localized("No organization selected"))
            }
        }
        .defaultSize(width: 480, height: 520)

        Window(Text(localized("Open object")), id: WindowID.objectPrompt) {
            if let organizationForObjectPrompt {
                ObjectIdPromptView { objectId in
                    openObject(organization: organizationForObjectPrompt, objectId: objectId)
                }
            } else {
                Text(localized("No organization selected"))
            }
        }
        .defaultSize(width: 380, height: 190)
        
    }
}
