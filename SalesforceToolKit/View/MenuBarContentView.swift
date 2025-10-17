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
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var viewOrganizationDetailsWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var exportPreference: () -> Void
    var importPreference: () -> Void
    var confirmQuit: () -> Void
    
    @Binding var biometricAuthenticationEnabled: Bool
    var isTouchIDAvailable: Bool
    
    var body: some View {
        let orgs = authenticatedOrgManager.authenticatedOrgs
        let cli = SalesforceCLI()
        
        if (orgs.isEmpty) {
            Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
        } else {
            let favorites = authenticatedOrgManager.authenticatedOrgs.filter{ $0.isFavorite == true }
            let defaultOrg = orgs.filter{ $0.isDefault == true }.first
            
            Button("Salesforce Toolkit - v2.3.0"){
                mainWindow()
            }
            .disabled(true)
            
            Button(){
                
            } label: {
                Image(systemName: "star.fill")
                Text("\(defaultOrg?.label ?? "Ninguna") (\(defaultOrg?.orgId ?? "Ninguna"))")
                Text("\(defaultOrg?.instanceUrl ?? "Ninguna")")
                    .font(.system(size: 10))
            }
            
            Divider()
            
            if favorites.isEmpty {
                Button(){} label: {
                    Image(systemName: "heart.fill")
                    Text("No hay favoritos")
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
                        confirmLogout: confirmLogout,
                        confirmDelete: confirmDelete
                    )
                    .environmentObject(authenticatedOrgManager)
                }
            }
            
            Divider()
            
            Menu("Organizaciones autenticadas (\(orgs.count))") {
                if orgs.isEmpty {
                    Button("No organizaciones autenticadas"){}.disabled(true)
                } else {
                    ForEach(orgs) { org in
                        OrgMenuItem(
                            org: org,
                            authenticateIfRequired: authenticateIfRequired,
                            cli: cli,
                            isFavorite: false,
                            viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                            openEditAuthenticationWindow: openEditAuthenticationWindow,
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
                    Text("Autenticar nueva organización...")
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
            
            Menu("Request new org") {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Specialized}) { link in
                    Button(){
                        let _ = cli.openUrl(url: link.url)
                    } label: {
                        Image(systemName: "network")
                        Text(link.label)
                    }
                }
            }
            
            Divider()
            
            Menu("Tools"){
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
            
            Menu("DevOp Tools") {
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
            
            Menu("Help") {
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
            let _ = cli.update()
            
            let content = UNMutableNotificationContent()
            content.title = "Actualización exitosa"
            content.body = "Se ha actualizado correctamente la versión de Salesforce CLI en su sistema."
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
        
        Divider()
        
        Button() {
            let _ = cli.openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
        } label: {
            Text(NSLocalizedString("Sponsor Salesforce ToolKit on Github", comment: ""))
            Text("Your support matters")
        }
        
        Divider()
        
        Button(NSLocalizedString("Quit", comment: "")) {
            confirmQuit()
        }
        .keyboardShortcut("q")
    }
}

