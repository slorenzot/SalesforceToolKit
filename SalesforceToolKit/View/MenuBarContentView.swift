import SwiftUI
import UserNotifications

struct MenuBarContentView: View {
    @AppStorage("defaultBrowser") private var defaultBrowser: String = "chrome"
    
    @ObservedObject var keyMonitor: KeyMonitor
    @ObservedObject var authenticatedOrgManager: AuthenticatedOrgManager
    @Binding var launchOnLogin: Bool
    var setLaunchOnLogin: (Bool) -> Void
    var credentialManager: LinkManager
    var version: String
    
    var openAuthenticationWindow: () -> Void
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var confirmQuit: () -> Void
    
    let SETUP_PATH = "/lightning/setup/SetupOneHome/home"
    let DEVCONSOLE_PATH = "/_ui/common/apex/debug/ApexCSIPage"
    let SCHBUILDER_PATH = "/lightning/setup/SchemaBuilder/home"
    
    var body: some View {
        Button("Salesforce ToolKit (version \(version))"){}
            .disabled(true)
        Divider()
        
        Button(){
            openAuthenticationWindow()
        } label: {
            Image(systemName: "key.icloud.fill")
            Text("Autenticar y abrir organización...")
        }
        
        Divider()
        
        if (credentialManager.storedLinks.isEmpty) {
            Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
        } else {
            Menu("Organizaciones autenticadas") {
                if authenticatedOrgManager.authenticatedOrgs.isEmpty {
                    Button("No authenticated orgs"){}.disabled(true)
                } else {
                    ForEach(authenticatedOrgManager.authenticatedOrgs) { org in
                        Menu {
                            Button() {
                                let cli = SalesforceCLI()
                                let _ = cli.open(alias: org.alias,browser: defaultBrowser)
                            } label: {
                               Image(systemName: "network")
                               Text("Abrir instancia...")
                            }
                           
                            Button("Abrir instancia en navegación privada...") {
                                let cli = SalesforceCLI()
                                let success = cli.open(alias: org.alias, incognito: true, browser: defaultBrowser)
                                
                                if (!success) {
                                    let content = UNMutableNotificationContent()
                                    content.title = "Opening Org Failed"
                                    content.body = "Error opening to \(org.alias), the main reason is your default browser do not support this Salesforce feature..."
                                    content.sound = UNNotificationSound.default

                                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                                    UNUserNotificationCenter.current().add(request)
                                }
                            }
                            
                            Menu {
                                
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: SCHBUILDER_PATH)
                                } label: {
                                    Image(systemName: "map.fill")
                                    Text("Abrir generador de esquemas")
                                }
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: DEVCONSOLE_PATH)
                                } label: {
                                    Image(systemName: "terminal.fill")
                                    Text("Abrir consola de desarrollador")
                                }
                                
                                Divider()
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: SETUP_PATH)
                                } label: {
                                    Image(systemName: "gearshape")
                                    Text("Abrir configuración...")
                                }
                                
                            } label: {
                                Text("Desarrollador")
                            }
                            
                            Divider()
                            
                            Button("Preferencias...") {
                                openEditAuthenticationWindow(org)
                            }
                            
                            Divider()
                            
                            Button("Salir...") {
                                confirmLogout(org)
                            }
                            
                            
                            Divider()
                            
                            Button("Eliminar...") {
                                confirmDelete(org)
                            }
                        } label: {
                            Image(systemName: "key.icloud.fill")
                            Text(keyMonitor.altKeyPressed ? (org.orgId ?? "No Org ID") : "\(org.label) (\(org.orgType))")
                        }
                    }
                }
            }
            
            Divider()
            
            ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Org}) { link in
                Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                    openUrl(url: link.url)
                }
            }
            
            Divider()
            
            Menu("Request new org") {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Specialized}) { link in
                    Button(NSLocalizedString("Request", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                }
            }
            
            Divider()
            
            Menu("Tools"){
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Toolbox}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                }
            }
            
            Divider()
            
            Menu("DevOp Tools") {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.DevOp}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                }
            }
            
            Divider()
            
            Menu("Help") {
                ForEach(credentialManager.storedLinks.filter{$0.type == LinkType.Help}) { link in
                    Button(NSLocalizedString("Open", comment: "") + " \(link.label)"){
                        openUrl(url: link.url)
                    }
                }
            }
        }
        
        Divider()
        Toggle(NSLocalizedString("Launch at Startup", comment: ""), isOn: $launchOnLogin)
            .onChange(of: launchOnLogin) { value in
                setLaunchOnLogin(value)
            }
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
