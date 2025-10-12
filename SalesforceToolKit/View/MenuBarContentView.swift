import SwiftUI
import UserNotifications

struct MenuBarContentView: View {
    @AppStorage("defaultBrowser") private var defaultBrowser: String = "chrome"
    
    @ObservedObject var keyMonitor: KeyMonitor
    @ObservedObject var authenticatedOrgManager: AuthenticatedOrgManager
    @Binding var launchOnLogin: Bool
    var setLaunchOnLogin: (Bool) async -> Void // MARK: - Changed closure type to async
    var credentialManager: LinkManager
    var version: String
    
    var mainWindow: () -> Void
    // FIX: Changed from a tuple type to a function type with labeled parameters.
    var authenticateIfRequired: (_ reason: String, _ action: @escaping () -> Void) -> Void
    var openAuthenticationWindow: () -> Void
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var viewOrganizationDetailsWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var confirmQuit: () -> Void
    
    // New properties for biometric authentication
    @Binding var biometricAuthenticationEnabled: Bool
    var isTouchIDAvailable: Bool
    
    var body: some View {
        let cli = SalesforceCLI() // Instantiate CLI once here and pass it down
        
        if (credentialManager.storedLinks.isEmpty) {
            Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
        } else {
            let orgs = authenticatedOrgManager.authenticatedOrgs
            let favorites = authenticatedOrgManager.authenticatedOrgs.filter{ $0.isFavorite == true }
            let defaultOrg = orgs.filter{ $0.isDefault == true }.first
            
            Button("Salesforce Toolkit - v2.3.0"){
                mainWindow()
            }
            
            Button(){
                
            } label: {
                Image(systemName: "star.fill")
                Text("Por defecto: \(defaultOrg?.label ?? "Ninguna")")
                Text("\(defaultOrg?.instanceUrl ?? "Ninguna")")
                Text("\(defaultOrg?.orgId ?? "Ninguna")")
            }
            
            Divider()
            
            //Menu() {
                if favorites.isEmpty {
                    Button(){} label: {
                        Image(systemName: "heart.fill")
                        Text("No hay favoritos")
                    }.disabled(true)
                } else {
                    ForEach(favorites) { org in
                        OrgMenuItem(
                            org: org,
                            defaultBrowser: defaultBrowser,
                            authenticateIfRequired: authenticateIfRequired,
                            cli: cli, // Pass the shared cli instance
                            isFavorite: true,
                            viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                            openEditAuthenticationWindow: openEditAuthenticationWindow,
                            confirmLogout: confirmLogout,
                            confirmDelete: confirmDelete
                        )
                        .environmentObject(authenticatedOrgManager) // Provide environment object
                    }
                }
            /*
             } label: {
                Image(systemName: "heart.fill")
                Text("Favoritas (\(favorites.count))")
            }
             */
            
            Divider()
            
            // REFACTOR: Use OrgMenuItem for authenticated orgs to avoid code duplication
            Menu("Organizaciones autenticadas (\(orgs.count))") {
                if orgs.isEmpty {
                    Button("No organizaciones autenticadas"){}.disabled(true)
                } else {
                    ForEach(orgs) { org in
                        OrgMenuItem(
                            org: org,
                            defaultBrowser: defaultBrowser,
                            authenticateIfRequired: authenticateIfRequired,
                            cli: cli, // Pass the shared cli instance
                            isFavorite: false,
                            viewOrganizationDetailsWindow: viewOrganizationDetailsWindow,
                            openEditAuthenticationWindow: openEditAuthenticationWindow,
                            confirmLogout: confirmLogout,
                            confirmDelete: confirmDelete
                        )
                        .environmentObject(authenticatedOrgManager) // Provide environment object
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
                    let _ = openUrl(url: link.url)
                }
            }
            
            Divider()
            
            Menu("Request new org") {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Specialized}) { link in
                    Button(){
                        let _ = openUrl(url: link.url)
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
                        let _ = openUrl(url: link.url)
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
                        let _ = openUrl(url: link.url)
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
                        let _ = openUrl(url: link.url)
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
        
        Button(NSLocalizedString("Preferences", comment: "")) {
            openPreferences()
        }
        .keyboardShortcut("p")
        
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
        
        Text("Versión actual: 1.0.0")
            .font(.system(size: 10))
            .disabled(true)
        
        Button(NSLocalizedString("Salesforce ToolKit (v\(version))", comment: "")) {
            let _ = openUrl(url: "https://github.com/slorenzot/SalesforceToolKit")
        }
        
        Divider()
        
        Button(NSLocalizedString("Quit", comment: "")) {
            confirmQuit()
        }
        .keyboardShortcut("q")
    }
}

