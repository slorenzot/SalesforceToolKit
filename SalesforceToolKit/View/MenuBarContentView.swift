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
    
    var mainWindow: () -> Void
    var openAuthenticationWindow: () -> Void
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var viewOrganizationDetailsWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var confirmQuit: () -> Void
    
    let SETUP_PATH = "/lightning/setup/SetupOneHome/home"
    let OBJECT_MANAGER_PATH = "/lightning/setup/ObjectManager/home"
    let DEVELOPER_CONSOLE_PATH = "/_ui/common/apex/debug/ApexCSIPage"
    let SCHEMA_BUILDER_PATH = "/lightning/setup/SchemaBuilder/home"
    let CODE_BUILDER_PATH = "/runtime_developerplatform_codebuilder/codebuilder.app?launch=true"
    let FLOW_PATH = "/lightning/setup/Flows/home"
    
    var body: some View {
        let cli = SalesforceCLI()
        
        if (credentialManager.storedLinks.isEmpty) {
            Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
        } else {
            let orgs = authenticatedOrgManager.authenticatedOrgs
            let favorites = authenticatedOrgManager.authenticatedOrgs.filter{ $0.isFavorite == true }
            let defaultOrg = orgs.filter{ $0.isDefault == true }.first
            
            Button("Salesforce Toolkit"){
                mainWindow()
            }
            
            Button(){
                
            } label: {
                Image(systemName: "star.fill")
                Text("Por defecto: \(defaultOrg?.label ?? "Ninguna")")
            }
            
            Divider()
            
            Menu() {
                if favorites.isEmpty {
                    Button("No hay organizaciones favoritas"){}.disabled(true)
                } else {
                    ForEach(favorites) { org in
                        Menu {
                            Button() {
                                let _ = cli.open(alias: org.alias,browser: defaultBrowser)
                            } label: {
                               Image(systemName: "network")
                               Text("Abrir instancia...")
                            }
                           
                            Button("Abrir instancia en navegación privada...") {
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
                                    let _ = cli.open(alias: org.alias, path: OBJECT_MANAGER_PATH)
                                } label: {
                                    Image(systemName: "cube.fill")
                                    Text("Gestor de objetos")
                                }
                                
                                Button() {
                                    let _ = cli.open(alias: org.alias, path: SCHEMA_BUILDER_PATH)
                                } label: {
                                    Image(systemName: "map.fill")
                                    Text("Generador de esquemas")
                                }
                                
                                Button() {
                                    let _ = cli.open(alias: org.alias, path: CODE_BUILDER_PATH)
                                } label: {
                                    Image(systemName: "display.and.screwdriver")
                                    Text("Generador de código")
                                }
                                
                                Button() {
                                    let _ = cli.open(alias: org.alias, path: FLOW_PATH)
                                } label: {
                                    Image(systemName: "wind")
                                    Text("Flujos")
                                }
                                
                                Divider()
                                
                                Button() {
                                    let _ = cli.open(alias: org.alias, path: DEVELOPER_CONSOLE_PATH)
                                } label: {
                                    Image(systemName: "terminal.fill")
                                    Text("Consola de desarrollador")
                                }
                                
                            } label: {
                                Text("Herramientas de Desarrollo")
                            }
                            
                            Divider()
                            
                            Button() {
                                let _ = cli.open(alias: org.alias, path: SETUP_PATH)
                            } label: {
                                Image(systemName: "gearshape")
                                Text("Configuración...")
                            }
                        } label: {
                            Image(systemName: "key.icloud.fill")
                            Text("\(org.label) (\(org.orgType))")
                        }
                    }
                }
            } label: {
                Image(systemName: "heart.fill")
                Text("Favoritas (\(favorites.count))")
            }
            
            Divider()
            
            Menu("Organizaciones autenticadas (\(orgs.count))") {
                if orgs.isEmpty {
                    Button("No organizaciones autenticadas"){}.disabled(true)
                } else {
                    ForEach(orgs) { org in
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
                                    let _ = cli.open(alias: org.alias, path: OBJECT_MANAGER_PATH)
                                } label: {
                                    Image(systemName: "cube.fill")
                                    Text("Gestor de objetos")
                                }
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: SCHEMA_BUILDER_PATH)
                                } label: {
                                    Image(systemName: "map.fill")
                                    Text("Generador de esquemas")
                                }
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: CODE_BUILDER_PATH)
                                } label: {
                                    Image(systemName: "display.and.screwdriver")
                                    Text("Generador de código")
                                }
                                
                                Button() {
                                    let cli = SalesforceCLI()
                                    let _ = cli.open(alias: org.alias, path: FLOW_PATH)
                                } label: {
                                    Image(systemName: "wind")
                                    Text("Flujos")
                                }
                                
                                Divider()
                                
                                Button() {
                                    let _ = cli.open(alias: org.alias, path: DEVELOPER_CONSOLE_PATH)
                                } label: {
                                    Image(systemName: "terminal.fill")
                                    Text("Consola de desarrollador")
                                }
                                
                            } label: {
                                Text("Herramientas de Desarrollo")
                            }
                            
                            Divider()
                            
                            Button() {
                                let cli = SalesforceCLI()
                                let _ = cli.open(alias: org.alias, path: SETUP_PATH)
                            } label: {
                                Image(systemName: "gearshape")
                                Text("Configuración...")
                            }
                            
                            Divider()
                            
                            Button("Mostrar detalles") {
                                viewOrganizationDetailsWindow(org)
                            }
                            
                            Divider()
                            
                            Button("Preferencias...") {
                                openEditAuthenticationWindow(org)
                            }
                            
                            Toggle(isOn: Binding<Bool>(
                                get: { org.isFavorite ?? false },
                                set: { newValue in
                                    var mutableOrg = org
                                    mutableOrg.isFavorite = newValue
                                    authenticatedOrgManager.updateOrg(org: mutableOrg)
                                }
                            )) {
                                Text("Es favorita")
                            }
                            
                            Toggle(isOn: Binding<Bool>(
                                get: { org.isDefault ?? false },
                                set: { newValue in
                                    var mutableOrg = org
                                    mutableOrg.isDefault = newValue
                                    authenticatedOrgManager.setDefaultOrg(org: mutableOrg)
                                }
                            )) {
                                Text("Por defecto")
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
                            Text("\(org.label) (\(org.orgType))")
                        }
                    }
                }
                
                Divider()
                Button(){
                    openAuthenticationWindow()
                } label: {
                    Image(systemName: "plus.circle")
                    Text("Autenticar organización...")
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
                setLaunchOnLogin(value)
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
