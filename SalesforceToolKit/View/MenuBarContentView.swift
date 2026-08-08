import SwiftUI
import UserNotifications
import AppKit // Required for NSWorkspace

// MARK: - MenuBarContentView

struct MenuBarContentView: View {    
    @ObservedObject var keyMonitor: KeyMonitor
    @ObservedObject var authenticatedOrgManager: AuthenticatedOrgManager
    @Binding var launchOnLogin: Bool
    var setLaunchOnLogin: (Bool) async -> Void
    var credentialManager: LinkManager
    var version: String
    
    var mainWindow: () -> Void
    var authenticateIfRequired: (_ reason: String, _ action: @escaping () -> Void) -> Void
    var openAuthenticationWindow: () -> Void
    var openObjectPromptWindow: (AuthenticatedOrg) -> Void
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var viewOrganizationDetailsWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var exportPreference: () -> Void
    var importPreference: () -> Void
    var confirmQuit: () -> Void
    var openCLIUpdateWindow: () -> Void
    
    @Binding var biometricAuthenticationEnabled: Bool
    var isTouchIDAvailable: Bool
    
    var appIsUpdated: Bool

    
    var body: some View {
        let orgs = authenticatedOrgManager.authenticatedOrgs
        let cli = SalesforceCLI()
        
        Button() {
            if appIsUpdated {
                mainWindow()
            } else {
                openUrl(url: "https://github.com/slorenzot/SalesforceToolKit/releases")
            }
        } label: {
            Image(systemName: "cloud.fill")
            Text(localized("Salesforce Toolkit"))
            if (!appIsUpdated) {
                Text(NSLocalizedString("New version is availabe, click to update now!", comment: "text"))
            } else {
                Text(NSLocalizedString("Great, you hava latest version!", comment: "text"))
            }
            
        }
        .disabled(appIsUpdated)
        
        Divider()
        
        if (orgs.isEmpty) {
            Button(NSLocalizedString("No tienes instancias almacenadas...", comment: "text")){}.disabled(true)
            
            Divider()
            
            Button(){
                openAuthenticationWindow()
            } label: {
                Image(systemName: "plus.circle")
                Text(NSLocalizedString("Autenticar nueva organización...", comment: "text"))
                Text(NSLocalizedString("No tienes instancias almacenadas", comment: "text"))
            }
            
        } else {
            let favorites = authenticatedOrgManager.authenticatedOrgs.filter{ $0.isFavorite == true }
            let defaultOrg = orgs.filter{ $0.isDefault == true }.first
            
            Button(){} label: {
                Image(systemName: "star.fill")
                Text("\(defaultOrg?.label ?? localized("None")) (\(defaultOrg?.orgId ?? localized("None")))")
                Text("\(defaultOrg?.instanceUrl ?? localized("None"))")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            if favorites.isEmpty {
                Button(){} label: {
                    Image(systemName: "heart.fill")
                    Text(localized("No favorites"))
                }.disabled(true)
            } else {
                ForEach(favorites) { org in
                    OrgMenuItem(
                        org: org,
                        authenticateIfRequired: authenticateIfRequired,
                        cli: cli,
                        isFavorite: true,
                        viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                        openEditAuthenticationWindow: openEditAuthenticationWindow,
                        openObjectPromptWindow: openObjectPromptWindow,
                        confirmLogout: confirmLogout,
                        confirmDelete: confirmDelete
                    )
                    .environmentObject(authenticatedOrgManager)
                }
            }
            
            Divider()
            
            Menu(localized("Authenticated organizations (%lld)", orgs.count)) {
                if orgs.isEmpty {
                    Button(localized("No authenticated organizations")){}.disabled(true)
                } else {
                    ForEach(orgs) { org in
                        OrgMenuItem(
                            org: org,
                            authenticateIfRequired: authenticateIfRequired,
                            cli: cli,
                            isFavorite: false,
                            viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                            openEditAuthenticationWindow: openEditAuthenticationWindow,
                            openObjectPromptWindow: openObjectPromptWindow,
                            confirmLogout: confirmLogout,
                            confirmDelete: confirmDelete
                        )
                        .environmentObject(authenticatedOrgManager)
                    }
                }
                
                Divider()
                
                Button(){
                    openAuthenticationWindow()
                } label: {
                    Image(systemName: "plus.circle")
                    Text(localized("Authenticate new organization..."))
                }
            }
            
            Divider()
            
            ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Org}) { link in
                Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                    // Ahora se usa el nuevo openUrl que permite especificar el navegador
                    let _ = cli.openUrl(url: link.url)
                }
            }
            
            Divider()
            
            Menu(localized("Request new organization")) {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Specialized}) { link in
                    Button(){
                        let _ = cli.openUrl(url: link.url)
                    } label: {
                        Image(systemName: "network")
                        Text(localized(link.label))
                    }
                }
            }
            
            Divider()
            
            Menu(localized("Tools")){
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Toolbox}) { link in
                    Button() {
                        let _ = cli.openUrl(url: link.url)
                    } label: {
                        Image(systemName: "network")
                        Text(link.label)
                    }
                }
            }
            
            Divider()
            
            Menu(localized("DevOps tools")) {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.DevOp}) { link in
                    Button() {
                        let _ = cli.openUrl(url: link.url)
                    } label: {
                        Image(systemName: "network")
                        Text(link.label)
                    }
                }
            }
            
            Divider()
            
            Menu(localized("Help")) {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Help}) { link in
                    Button(link.label) {
                        let _ = cli.openUrl(url: link.url)
                    }
                }
            }
        }
        
        Divider()
        
        Toggle(NSLocalizedString("Launch at Startup", comment: ""), isOn: $launchOnLogin)
            .onChange(of: launchOnLogin) { value in
                Task {
                    await setLaunchOnLogin(value)
                }
            }
            .toggleStyle(.checkbox)
        
        Divider()
        
        Button(NSLocalizedString("Preferences...", comment: "")) {
            openPreferences()
        }
        .keyboardShortcut("p")
        
        if (!orgs.isEmpty) {
            Button(NSLocalizedString("Exportar...", comment: "")) {
                exportPreference()
            }
        }
        
        Button(NSLocalizedString("Importar...", comment: "")) {
            importPreference()
        }
        
        Divider()
        
        Button(NSLocalizedString("Actualizar Salesforce CLI", comment: "")){
            openCLIUpdateWindow()
        }
        
        Divider()
        
        Button() {
            let _ = cli.openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
        } label: {
            Text(NSLocalizedString("Sponsor Salesforce ToolKit on Github", comment: ""))
            Text(NSLocalizedString("Your support matters", comment: ""))
        }
        
        Divider()
        
        Button(NSLocalizedString("Quit", comment: "")) {
            confirmQuit()
        }
        .keyboardShortcut("q")
    }
}

/// Window displayed while Salesforce CLI is being updated.
struct CLIUpdateView: View {
    private enum UpdateState: Equatable {
        case updating
        case succeeded
        case failed
    }

    @Environment(\.dismiss) private var dismiss
    @State private var state: UpdateState = .updating

    var body: some View {
        VStack(spacing: 18) {
            Group {
                switch state {
                case .updating:
                    ProgressView()
                        .controlSize(.large)
                    Text(localized("Updating Salesforce CLI..."))
                case .succeeded:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.green)
                    Text(localized("Salesforce CLI was successfully updated on your system."))
                        .multilineTextAlignment(.center)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.red)
                    Text(localized("Salesforce CLI could not be updated."))
                        .multilineTextAlignment(.center)
                }
            }

            if state != .updating {
                Button(localized("Close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(width: 360, height: 190)
        .task {
            let didUpdate = await Task.detached(priority: .userInitiated) {
                SalesforceCLI().update()
            }.value

            state = didUpdate ? .succeeded : .failed
            postCLIUpdateNotification(succeeded: didUpdate)
        }
    }

    private func postCLIUpdateNotification(succeeded: Bool) {
        let content = UNMutableNotificationContent()
        content.title = localized(succeeded ? "Update successful" : "Update failed")
        content.body = localized(
            succeeded
                ? "Salesforce CLI was successfully updated on your system."
                : "Salesforce CLI could not be updated."
        )
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
