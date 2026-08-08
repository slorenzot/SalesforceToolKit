import SwiftUI
import UserNotifications
import AppKit // Import AppKit for NSPasteboard

// MARK: - Browser Detection Helpers

/// Una estructura para representar un navegador web instalado.


/// Detecta navegadores web comunes instalados en el sistema macOS.
/// - Returns: Un array de estructuras `Browser` para cada navegador detectado.
func detectInstalledBrowsers() -> [Browser] {
    var detectedBrowsers: [Browser] = []

    // Define una lista de navegadores comunes y sus identificadores de paquete conocidos.
    // Esta lista se puede extender según sea necesario.
    let potentialBrowsers: [Browser] = [
        Browser(name: "chrome", label: "Google Chrome", bundleIdentifier: "com.google.Chrome"),
        Browser(name: "firefox", label: "Firefox", bundleIdentifier: "org.mozilla.firefox"),
        Browser(name: "edge", label: "Microsoft Edge", bundleIdentifier: "com.microsoft.Edge"), // Corregido el nombre a "edge" para coincidir con el uso anterior
        // Agrega más navegadores aquí si lo deseas
    ]

    for browser in potentialBrowsers {
        // Usa NSWorkspace para encontrar la URL de la aplicación basándose en su identificador de paquete.
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) {
            // Verifica que el paquete de la aplicación realmente exista en la ruta resuelta.
            if FileManager.default.fileExists(atPath: appURL.path) {
                detectedBrowsers.append(browser)
            }
        }
    }
    return detectedBrowsers
}

func notifySalesforceNotOutdated() {
    let content = UNMutableNotificationContent()
    content.title = localized("Salesforce CLI is outdated")
    content.body = localized("Update Salesforce CLI from the menu bar before opening an organization.")
    content.sound = UNNotificationSound.default

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
}

struct OrgMenuItem: View {
    let org: AuthenticatedOrg
    let authenticateIfRequired: (_ reason: String, _ action: @escaping () -> Void) -> Void
    let cli: SalesforceCLI // Use this passed-down CLI instance
    let isFavorite: Bool
    let viewOrganizationDetailsWindow: (_ org: AuthenticatedOrg) -> Void
    let openEditAuthenticationWindow: (_ org: AuthenticatedOrg) -> Void
    let openObjectPromptWindow: (_ org: AuthenticatedOrg) -> Void
    let confirmLogout: (_ org: AuthenticatedOrg) -> Void
    let confirmDelete: (_ org: AuthenticatedOrg) -> Void

    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager


    let SETUP_PATH = "/lightning/setup/SetupOneHome/home"
    let NAVIGATION_MENUS_PATH = "/lightning/setup/NavigationMenus/home"
    let OBJECT_MANAGER_PATH = "/lightning/setup/ObjectManager/home"
    let DEVELOPER_CONSOLE_PATH = "/_ui/common/apex/debug/ApexCSIPage"
    let SCHEMA_BUILDER_PATH = "/lightning/setup/SchemaBuilder/home"
    let CODE_BUILDER_PATH = "/runtime_developerplatform_codebuilder/codebuilder.app?launch=true"
    let FLOW_PATH = "/lightning/setup/Flows/home"
    let PROFILES_PATH = "/lightning/setup/Profiles/home"
    let PERMISSION_SETS_PATH = "/lightning/setup/PermSets/home"
    let PERMISSION_SET_GROUPS_PATH = "/lightning/setup/PermSetGroups/home"
    let CUSTOM_PERMISSIONS_PATH = "/lightning/setup/CustomPermissions/home"
    let USERS_PATH = "/lightning/setup/ManageUsers/home"
    let ROLES_PATH = "/lightning/setup/Roles/home"
    let PUBLIC_GROUPS_PATH = "/lightning/setup/PublicGroups/home"
    let APEX_CLASSES_PATH = "/lightning/setup/ApexClasses/home"
    let APEX_TRIGGERS_PATH = "/lightning/setup/ApexTriggers/home"
    let APEX_TEST_EXECUTION_PATH = "/lightning/setup/ApexTestQueue/home"
    let DEBUG_LOGS_PATH = "/lightning/setup/ApexDebugLogs/home"
    let CUSTOM_METADATA_PATH = "/lightning/setup/CustomMetadata/home"
    let CUSTOM_SETTINGS_PATH = "/lightning/setup/CustomSettings/home"
    let APPROVAL_PROCESSES_PATH = "/lightning/setup/ApprovalProcesses/home"
    let ASSIGNMENT_RULES_PATH = "/lightning/setup/AssignmentRules/home"
    let WORKFLOW_RULES_PATH = "/lightning/setup/WorkflowRules/home"
    let NAMED_CREDENTIALS_PATH = "/lightning/setup/NamedCredential/home"
    let CONNECTED_APPS_PATH = "/lightning/setup/ConnectedApplication/home"
    let REMOTE_SITE_SETTINGS_PATH = "/lightning/setup/SecurityRemoteProxy/home"
    let DEPLOYMENT_STATUS_PATH = "/lightning/setup/DeployStatus/home"
    let APEX_JOBS_PATH = "/lightning/setup/AsyncApexJobs/home"
    let SCHEDULED_JOBS_PATH = "/lightning/setup/ScheduledJobs/home"
    let OBJECT_PATH = "/lightning/o/<ObjectName>/home"

    var body: some View {

        let availableBrowsers = detectInstalledBrowsers()

        Menu {
            Text("\(org.label)")

            Divider()

            Menu {
                Button() {
                    // Copy Org ID to pasteboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(org.orgId ?? "", forType: .string)
                } label: {
                    Text(localized("Org ID: %@", org.orgId ?? "--"))
                    Text(localized("Copy to clipboard"))
                }
                Button() {
                    // Copy Instance URL to pasteboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(org.instanceUrl ?? "", forType: .string)
                } label: {
                    Text(localized("Instance URL: %@", org.instanceUrl ?? "--"))
                    Text(localized("Copy to clipboard"))
                }
                Button() {
                    // Copy Alias to pasteboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(org.alias, forType: .string)
                } label: {
                    Text(localized("Alias: %@", org.alias))
                    Text(localized("Copy to clipboard"))
                }
            } label: {
                Text(localized("Copy"))
            }

            Divider()

            Button {
                openObjectPromptWindow(org)
            } label: {
                Image(systemName: "cube")
                Text(localized("Open object"))
            }

            Divider()

            Button() {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org window", comment: "")) {
                    if(cli.isOutdated()) {
                        return notifySalesforceNotOutdated()
                    }

                    let _ = cli.open(alias: org.alias, browser: org.useBrowser ?? "default")
                }
            } label: {
               Image(systemName: "network")
               Text(localized("Open organization..."))
            }

            Button(localized("Open organization in private browsing...")) {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
                    if(cli.isOutdated()) {
                        return notifySalesforceNotOutdated()
                    }

                    let success = cli.open(alias: org.alias, incognito: true, browser: org.useBrowser ?? "default")

                    if (!success) {
                        let content = UNMutableNotificationContent()
                        content.title = localized("Opening organization failed")
                        content.body = localized("Could not open %@. Your default browser may not support this Salesforce feature.", org.alias)
                        content.sound = UNNotificationSound.default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }

            Button(localized("Open organization as...")) {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
                    if(cli.isOutdated()) {
                        return notifySalesforceNotOutdated()
                    }

                    let success = cli.openAsUser(userId: "005Hs00000BVy3m", alias: org.alias, incognito: false, browser: org.useBrowser ?? "default")

                    if (!success) {
                        let content = UNMutableNotificationContent()
                        content.title = localized("Opening organization failed")
                        content.body = localized("Could not open %@. Your default browser may not support this Salesforce feature.", org.alias)
                        content.sound = UNNotificationSound.default

                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }.disabled(true)

            Menu {
                setupMenuItem(label: "Settings...", path: SETUP_PATH, icon: "gearshape.fill", reason: "Authenticate to open show Settings window")
                setupMenuItem(label: "App Manager", path: NAVIGATION_MENUS_PATH, icon: "list.bullet.rectangle.fill", reason: "Authenticate to open Org App Manager window")
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open show Org details window", comment: "")) {
                        if cli.isOutdated() { return notifySalesforceNotOutdated() }
                        viewOrganizationDetailsWindow(org)
                    }
                } label: {
                    Image(systemName: "flag.fill")
                    Text(localized("Details and limits..."))
                }
            } label: {
                Label(localized("Administration"), systemImage: "gearshape.2.fill")
            }

            Menu {
                setupMenuItem(label: "Profiles", path: PROFILES_PATH, icon: "person.2.fill", reason: "Authenticate to open Org Profiles window")
                setupMenuItem(label: "Permission Sets", path: PERMISSION_SETS_PATH, icon: "person.badge.key.fill", reason: "Authenticate to open Org Permission Sets window")
                setupMenuItem(label: "Permission Set Groups", path: PERMISSION_SET_GROUPS_PATH, icon: "person.3.fill", reason: "Authenticate to open Org Permission Set Groups window")
                setupMenuItem(label: "Custom Permissions", path: CUSTOM_PERMISSIONS_PATH, icon: "checkmark.shield.fill", reason: "Authenticate to open Org Custom Permissions window")
                setupMenuItem(label: "Users", path: USERS_PATH, icon: "person.crop.circle.fill", reason: "Authenticate to open Org Users window")
                setupMenuItem(label: "Roles", path: ROLES_PATH, icon: "person.2.wave.2.fill", reason: "Authenticate to open Org Roles window")
                setupMenuItem(label: "Public Groups", path: PUBLIC_GROUPS_PATH, icon: "person.3.sequence.fill", reason: "Authenticate to open Org Public Groups window")
            } label: {
                Label(localized("Security and access"), systemImage: "lock.shield.fill")
            }

            Menu {
                setupMenuItem(label: "Code builder", path: CODE_BUILDER_PATH, icon: "display.and.screwdriver", reason: "Authenticate to open Org Code BUilder window")
                setupMenuItem(label: "Developer console", path: DEVELOPER_CONSOLE_PATH, icon: "terminal.fill", reason: "Authenticate to open Org Developer Console window")
                setupMenuItem(label: "Apex Classes", path: APEX_CLASSES_PATH, icon: "curlybraces.square.fill", reason: "Authenticate to open Org Apex Classes window")
                setupMenuItem(label: "Apex Triggers", path: APEX_TRIGGERS_PATH, icon: "bolt.fill", reason: "Authenticate to open Org Apex Triggers window")
                setupMenuItem(label: "Apex Test Execution", path: APEX_TEST_EXECUTION_PATH, icon: "checkmark.circle.fill", reason: "Authenticate to open Org Apex Test Execution window")
            } label: {
                Label(localized("Development"), systemImage: "hammer.fill")
            }

            Menu {
                setupMenuItem(label: "Object manager", path: OBJECT_MANAGER_PATH, icon: "cube.fill", reason: "Authenticate to open Org Object Manager window")
                setupMenuItem(label: "Schema builder", path: SCHEMA_BUILDER_PATH, icon: "map.fill", reason: "Authenticate to open Org Schema Builder window")
                setupMenuItem(label: "Custom Metadata Types", path: CUSTOM_METADATA_PATH, icon: "doc.badge.gearshape.fill", reason: "Authenticate to open Org Custom Metadata Types window")
                setupMenuItem(label: "Custom Settings", path: CUSTOM_SETTINGS_PATH, icon: "slider.horizontal.3", reason: "Authenticate to open Org Custom Settings window")
            } label: {
                Label(localized("Data and model"), systemImage: "square.3.layers.3d")
            }

            Menu {
                setupMenuItem(label: "Flows", path: FLOW_PATH, icon: "wind", reason: "Authenticate to open Org Flow Manager window")
                setupMenuItem(label: "Approval Processes", path: APPROVAL_PROCESSES_PATH, icon: "checkmark.seal.fill", reason: "Authenticate to open Org Approval Processes window")
                setupMenuItem(label: "Assignment Rules", path: ASSIGNMENT_RULES_PATH, icon: "arrow.triangle.branch", reason: "Authenticate to open Org Assignment Rules window")
                setupMenuItem(label: "Workflow Rules", path: WORKFLOW_RULES_PATH, icon: "arrow.clockwise", reason: "Authenticate to open Org Workflow Rules window")
            } label: {
                Label(localized("Automation"), systemImage: "gearshape.2.fill")
            }

            Menu {
                setupMenuItem(label: "Named Credentials", path: NAMED_CREDENTIALS_PATH, icon: "key.fill", reason: "Authenticate to open Org Named Credentials window")
                setupMenuItem(label: "Connected Apps", path: CONNECTED_APPS_PATH, icon: "app.connected.to.app.below.fill", reason: "Authenticate to open Org Connected Apps window")
                setupMenuItem(label: "Remote Site Settings", path: REMOTE_SITE_SETTINGS_PATH, icon: "network.badge.shield.half.filled", reason: "Authenticate to open Org Remote Site Settings window")
            } label: {
                Label(localized("Integrations"), systemImage: "arrow.triangle.2.circlepath")
            }

            Menu {
                setupMenuItem(label: "Debug Logs", path: DEBUG_LOGS_PATH, icon: "ladybug.fill", reason: "Authenticate to open Org Debug Logs window")
                setupMenuItem(label: "Deployment Status", path: DEPLOYMENT_STATUS_PATH, icon: "shippingbox.fill", reason: "Authenticate to open Org Deployment Status window")
                setupMenuItem(label: "Apex Jobs", path: APEX_JOBS_PATH, icon: "list.bullet.rectangle.fill", reason: "Authenticate to open Org Apex Jobs window")
                setupMenuItem(label: "Scheduled Jobs", path: SCHEDULED_JOBS_PATH, icon: "calendar.badge.clock", reason: "Authenticate to open Org Scheduled Jobs window")
            } label: {
                Label(localized("Monitoring and deployment"), systemImage: "chart.bar.fill")
            }

            Divider()

            Button() {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org window", comment: "")) {
                    if(cli.isOutdated()) {
                        return notifySalesforceNotOutdated()
                    }

                    let _ = cli.open(alias: org.alias, path: SETUP_PATH, browser: org.useBrowser ?? "default")
                }
            } label: {
                Image(systemName: "gearshape")
                Text(localized("Setup..."))
            }

            if (!isFavorite) {

                Divider()

                Button(localized("Organization preferences...")) {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org settings window", comment: "")) {
                        openEditAuthenticationWindow(org)
                    }
                }

                Toggle(isOn: Binding<Bool>(
                    get: { org.isFavorite ?? false },
                    set: { newValue in
                        var mutableOrg = org
                        mutableOrg.isFavorite = newValue
                        authenticatedOrgManager.updateOrg(org: mutableOrg)
                    }
                )) {
                    Text(NSLocalizedString("Es favorito", comment: ""))
                }

                Toggle(isOn: Binding<Bool>(
                    get: { org.isDefault ?? false },
                    set: { newValue in
                        var mutableOrg = org
                        mutableOrg.isDefault = newValue
                        authenticatedOrgManager.setDefaultOrg(org: mutableOrg)
                    }
                )) {
                    Text(NSLocalizedString("Por defecto", comment: ""))
                }

                Divider()

                Menu() {
                    let browsers: [String] = ["default", "chrome", "firefox", "edge"]

                    // Fixed: Use ForEach SwiftUI view instead of Sequence.forEach method
                    ForEach(browsers, id: \.self) { browserName in
                        if availableBrowsers.contains(where: { $0.name == browserName }) || browserName == "default" {
                            Button {
                                authenticateIfRequired(NSLocalizedString("Authenticate to set preferred browser for org", comment: "")) {
                                    var mutableOrg = org
                                    mutableOrg.useBrowser = NSLocalizedString(browserName, comment: "") // Use the existing 'useBrowser' property
                                    authenticatedOrgManager.updateOrg(org: mutableOrg)
                                }
                            } label: {
                                HStack {
                                    if org.useBrowser == browserName { // Check against 'useBrowser'
                                        Image(systemName: "checkmark")
                                    } else {
                                        // Hidden image for alignment when not selected
                                        Image(systemName: "checkmark").hidden()
                                    }
                                    Text(NSLocalizedString(browserName,  comment: "").capitalized)
                                }
                            }
                        }
                    }
                } label: {
                    Text(localized("Change browser"))
                    Text(localized("Currently using: %@", localized(org.useBrowser ?? "default")))
                }

                Divider()

                Button(localized("Sign out...")) {
                    authenticateIfRequired(NSLocalizedString("Authenticate to Logout Org", comment: "")) {
                        confirmLogout(org)
                    }
                }


                Divider()

                Button(localized("Delete...")) {
                    authenticateIfRequired(NSLocalizedString("Authenticate to Delete Org", comment: "")) {
                        confirmDelete(org)
                    }
                }
            }
        } label: {
            if (isFavorite) {
                Image(systemName: "heart.fill")
            } else {
                Image(systemName: "key.icloud.fill")
            }

            Text("\(org.label) (\(localizedOrganizationType(org.orgType)))")
        }
    }

    @ViewBuilder
    private func setupMenuItem(label: String, path: String, icon: String, reason: String) -> some View {
        Button {
            authenticateIfRequired(NSLocalizedString(reason, comment: "")) {
                if cli.isOutdated() {
                    return notifySalesforceNotOutdated()
                }

                let _ = cli.open(alias: org.alias, path: path, browser: org.useBrowser ?? "default")
            }
        } label: {
            Label(localized(label), systemImage: icon)
        }
    }

}

struct ObjectIdPromptView: View {
    @State private var objectId = ""
    @State private var validationMessage: String?
    @State private var isOpening = false
    @Environment(\.dismiss) private var dismiss

    let onOpen: (String) -> Void

    var body: some View {
        ZStack {
            if !isOpening {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localized("Open object"))
                        .font(.headline)

                    Text(localized("Enter the Salesforce record ID to open."))
                        .foregroundColor(.secondary)

                    TextField(localized("Object ID"), text: $objectId)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(open)

                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    HStack {
                        Spacer()
                        Button(localized("Cancel")) {
                            dismiss()
                        }
                        Button(localized("Open"), action: open)
                            .keyboardShortcut(.defaultAction)
                    }
                }
            }

            if isOpening {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(localized("Opening object, please wait..."))
                        .multilineTextAlignment(.center)
                    Text(localized("This window will close automatically when finished."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(width: 380, height: 190)
    }

    private func open() {
        let normalizedId = objectId.trimmingCharacters(in: .whitespacesAndNewlines)
        let isValid = (normalizedId.count == 15 || normalizedId.count == 18)
            && normalizedId.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }

        guard isValid else {
            validationMessage = localized("Enter a valid Salesforce ID with 15 or 18 alphanumeric characters.")
            return
        }

        isOpening = true
        DispatchQueue.main.async {
            onOpen(normalizedId)
            dismiss()
        }
    }
}
