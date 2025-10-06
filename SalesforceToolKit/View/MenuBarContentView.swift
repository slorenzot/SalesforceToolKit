import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var keyMonitor: KeyMonitor
    @ObservedObject var authenticatedOrgManager: AuthenticatedOrgManager
    @Binding var relaunchOnLogin: Bool
    var credentialManager: LinkManager
    var version: String
    
    var openAuthenticationWindow: () -> Void
    var openEditAuthenticationWindow: (AuthenticatedOrg) -> Void
    var confirmDelete: (AuthenticatedOrg) -> Void
    var confirmLogout: (AuthenticatedOrg) -> Void
    var openPreferences: () -> Void
    var confirmQuit: () -> Void
    
    let SETUP_PATH = "/lightning/setup/SetupOneHome/home"
    
    var body: some View {
        Button("Salesforce ToolKit (version \(version))"){}
            .disabled(true)
        Divider()
        
        Button(){
            openAuthenticationWindow()
        } label: {
            Image(systemName: "cloud.fill")
            Text("Authencate & Open Org...")
        }
        
        Divider()
        
        if (credentialManager.storedLinks.isEmpty) {
            Button(NSLocalizedString("No stored credentials...", comment: "text")){}.disabled(true)
        } else {
            Menu("Authenticated Orgs") {
                if authenticatedOrgManager.authenticatedOrgs.isEmpty {
                    Button("No authenticated orgs"){}.disabled(true)
                } else {
                    ForEach(authenticatedOrgManager.authenticatedOrgs) { org in
                        Menu {
                            Button("Abrir instancia...") {
                                let cli = SalesforceCLI()
                                cli.open(alias: org.alias)
                            }
                            Button("Abrir instancia en navegación privada...") {
                                let cli = SalesforceCLI()
                                cli.open(alias: org.alias, incognito: true)
                            }
                            Button("Abrir configuración de la Org...") {
                                let cli = SalesforceCLI()
                                cli.open(alias: org.alias, path: SETUP_PATH)
                            }
                            
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
                            Image(systemName: "cloud.fill")
                            Text(keyMonitor.altKeyPressed ? (org.orgId ?? "No Org ID") : "\(org.alias) (\(org.orgType))")
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
        Toggle(NSLocalizedString("Launch at Startup", comment: ""), isOn: $relaunchOnLogin)
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
