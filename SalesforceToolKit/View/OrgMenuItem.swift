import SwiftUI
import UserNotifications
import AppKit // Import AppKit for NSPasteboard

struct OrgMenuItem: View {
    let org: AuthenticatedOrg
    let defaultBrowser: String
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
                    let _ = cli.open(alias: org.alias,browser: defaultBrowser)
                }
            } label: {
               Image(systemName: "network")
               Text("Abrir instancia...")
            }
           
            Button("Abrir instancia en navegación privada...") {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
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
            }
            
            Button("Abrir instancia como...") {
                authenticateIfRequired(NSLocalizedString("Authenticate to open Org Private window", comment: "")) {
                    let success = cli.openAsUser(userId: "005Hs00000BVy3m", alias: org.alias, incognito: false, browser: defaultBrowser)
                    
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
                        let _ = cli.open(alias: org.alias, path: OBJECT_MANAGER_PATH, browser: defaultBrowser)
                    }
                } label: {
                    Image(systemName: "cube.fill")
                    Text("Gestor de objetos")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Schema Builder window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: SCHEMA_BUILDER_PATH, browser: defaultBrowser)
                    }
                } label: {
                    Image(systemName: "map.fill")
                    Text("Generador de esquemas")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Code BUilder window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: CODE_BUILDER_PATH, browser: defaultBrowser)
                    }
                } label: {
                    Image(systemName: "display.and.screwdriver")
                    Text("Generador de código")
                }
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Flow Manager window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: FLOW_PATH, browser: defaultBrowser)
                    }
                } label: {
                    Image(systemName: "wind")
                    Text("Flujos")
                }
                
                Divider()
                
                Button() {
                    authenticateIfRequired(NSLocalizedString("Authenticate to open Org Developer Console window", comment: "")) {
                        let _ = cli.open(alias: org.alias, path: DEVELOPER_CONSOLE_PATH, browser: defaultBrowser)
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
                    let _ = cli.open(alias: org.alias, path: SETUP_PATH, browser: defaultBrowser)
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
