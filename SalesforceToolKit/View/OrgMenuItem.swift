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

struct OrgMenuItem: View {
    let org: AuthenticatedOrg
    let authenticateIfRequired: (_ reason: String, _ action: @escaping () -> Void) -> Void
    let cli: SalesforceCLI // Use this passed-down CLI instance
    let isFavorite: Bool
    let viewOrganizationDetailsWindow: (_ org: AuthenticatedOrg) -> Void
    let openEditAuthenticationWindow: (_ org: AuthenticatedOrg) -> Void
    let confirmLogout: (_ org: AuthenticatedOrg) -> Void
    let confirmDelete: (_ org: AuthenticatedOrg) -> Void

    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager


    let SETUP_PATH = "/lightning/setup/SetupOneHome/home"
    let OBJECT_MANAGER_PATH = "/lightning/setup/ObjectManager/home"
    let DEVELOPER_CONSOLE_PATH = "/_ui/common/apex/debug/ApexCSIPage"
    let SCHEMA_BUILDER_PATH = "/lightning/setup/SchemaBuilder/home"
    let CODE_BUILDER_PATH = "/runtime_developerplatform_codebuilder/codebuilder.app?launch=true"
    let FLOW_PATH = "/lightning/setup/Flows/home"
    let OBJECT_PATH = "/lightning/o/<ObjectName>/home"

    var body: some View {
        
        let availableBrowsers = detectInstalledBrowsers()
        
        Menu {
            Text("\(org.label)")
            
            Divider()
            
            Button("Org ID: \(org.orgId ?? "--")") {
                // Copy Org ID to pasteboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(org.orgId ?? "", forType: .string)
            }
            Button("Enlace: \(org.instanceUrl ?? "--")") {
                // Copy Instance URL to pasteboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(org.instanceUrl ?? "", forType: .string)
            }
            Button("Alias: \(org.alias)") {
                // Copy Alias to pasteboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(org.alias, forType: .string)
            }

            Divider()
            
            Button() {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org window", comment: "")) {
                    let _ = cli.open(alias: org.alias, browser: org.useBrowser ?? "default")
                }
            } label: {
               Image(systemName: "network")
               Text("Abrir instancia...")
            }
           
            Button("Abrir instancia en navegación privada...") {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
                    let success = cli.open(alias: org.alias, incognito: true, browser: org.useBrowser ?? "default")
                    
                    if (!success) {
                        let content = UNMutableNotificationContent()
                        content.title = "Opening Org Failed"
                        content.body = "Error opening to \(org.alias), the main reason is your default browser do not support this Salesforce feature..."
                        content.sound = UNNotificationSound.default
                        
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
            
            Button("Abrir instancia como...") {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
                    let success = cli.openAsUser(userId: "005Hs00000BVy3m", alias: org.alias, incognito: false, browser: org.useBrowser ?? "default")
                    
                    if (!success) {
                        let content = UNMutableNotificationContent()
                        content.title = "Opening Org Failed"
                        content.body = "Error opening to \(org.alias), the main reason is your default browser do not support this Salesforce feature..."
                        content.sound = UNNotificationSound.default
                        
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }.disabled(true)
            
            Menu {
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open show Org details window", comment: "")) {
                        viewOrganizationDetailsWindow(org) // Corrected: Call the closure
                    }
                } label: {
                    Image(systemName: "flag.fill")
                    Text("Detalles y Límites...")
                }
                
                Divider()
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Object Manager window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: OBJECT_MANAGER_PATH, browser: org.useBrowser ?? "default")
                    }
                } label: {
                    Image(systemName: "cube.fill")
                    Text("Gestor de objetos")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Schema Builder window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: SCHEMA_BUILDER_PATH, browser: org.useBrowser ?? "default")
                    }
                } label: {
                    Image(systemName: "map.fill")
                    Text("Generador de esquemas")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Code BUilder window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: CODE_BUILDER_PATH, browser: org.useBrowser ?? "default")
                    }
                } label: {
                    Image(systemName: "display.and.screwdriver")
                    Text("Generador de código")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Flow Manager window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: FLOW_PATH, browser: org.useBrowser ?? "default")
                    }
                } label: {
                    Image(systemName: "wind")
                    Text("Flujos")
                }
                
                Divider()
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Developer Console window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: DEVELOPER_CONSOLE_PATH, browser: org.useBrowser ?? "default")
                    }
                } label: {
                    Image(systemName: "terminal.fill")
                    Text("Consola de desarrollador")
                }
                
            } label: {
                Text("Herramientas de Desarrollo")
            }
            
            Divider()
            
            Button() {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org window", comment: "")) {
                    let _ = cli.open(alias: org.alias, path: SETUP_PATH, browser: org.useBrowser ?? "default")
                }
            } label: {
                Image(systemName: "gearshape")
                Text("Configuración...")
            }
            
            if (!isFavorite) {
                
                Divider()
                
                Button("Preferencias...") {
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
                
                Menu("Usar navegador") {
                    let browsers: [String] = ["default", "chrome", "firefox", "edge"]
                    
                    // Fixed: Use ForEach SwiftUI view instead of Sequence.forEach method
                    ForEach(browsers, id: \.self) { browserName in
                        if availableBrowsers.contains(where: { $0.name == browserName || browserName == "default"}) {
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
                }
                
                Divider()
                
                Button("Salir...") {
                    authenticateIfRequired(NSLocalizedString("Authenticate to Logout Org", comment: "")) {
                        confirmLogout(org)
                    }
                }
                
                
                Divider()
                
                Button("Eliminar...") {
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
            
            Text("\(org.label) (\(org.orgType))")
        }
    }
}

