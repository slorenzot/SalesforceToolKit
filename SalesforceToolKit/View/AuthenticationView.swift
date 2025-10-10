import SwiftUI
import UserNotifications

fileprivate class AuthenticationWindowDelegate: NSObject, NSWindowDelegate {
    var isAuthenticating: Bool = false
    var onCancel: (() -> Void)?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isAuthenticating {
            let alert = NSAlert()
            alert.messageText = "Cancelar Autenticación"
            alert.informativeText = "¿Estás seguro de que quieres cancelar el proceso de inicio de sesión?"
            alert.addButton(withTitle: "Sí, cancelar")
            alert.addButton(withTitle: "No")
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                cli.killProcess(port: 1717)
                onCancel?()
                return true
            } else {
                return false
            }
        }
        return true
    }
}

struct AuthenticationView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var orgToEdit: AuthenticatedOrg?
    
    @State private var orgType: String
    @State private var label: String
    @State private var alias: String
    @State private var isFavorite: Bool = false
    @State private var isAuthenticating = false
    @State private var authenticationCancelled = false
    @State private var windowDelegate = AuthenticationWindowDelegate()
    @State private var thisWindow: NSWindow?
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager
    
    let orgTypes = ["Producción", "Desarrollo"]

    init(org: AuthenticatedOrg? = nil) {
        self.orgToEdit = org
        
        if let org = org {
            _orgType = State(initialValue: org.orgType)
            _label = State(initialValue: org.label)
            _alias = State(initialValue: org.alias)
            _isFavorite = State(initialValue: org.isFavorite ?? false)
        } else {
            _orgType = State(initialValue: "Producción")
            _label = State(initialValue: "")
            _alias = State(initialValue: "")
            _isFavorite = State(initialValue: false)
        }
    }

    private func generateAlias(from label: String) -> String {
        let newLabel = label.folding(options: .diacriticInsensitive, locale: .current).replacingOccurrences(of: " ", with: "-")
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return newLabel.lowercased()
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
    }

    var body: some View {
        ZStack {
            if !isAuthenticating {
                VStack {
                    Form {
                        Picker("Tipo de Org", selection: $orgType) {
                            ForEach(orgTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        TextField("Etiqueta", text: $label)
                            .onChange(of: label, perform: { value in
                                if orgToEdit == nil { // Only generate alias in create mode
                                    alias = generateAlias(from: value)
                                }
                            })
                            .disabled(orgToEdit != nil)
                        Text("La etiqueta es el nombre que se mostrará en Salesforce Toolkit para identificar fácilmente las instancias de su organización y puede contener espacios y caracteres especiales")
                            .font(.system(size: 10))
                        
                        TextField("Alias", text: $alias)
                            .disabled(true)
                        Text("El alias es usado por Salesforce CLI para ejecutar los comandos, no puede contener espacios ni caracteres especiales.")
                            .font(.system(size: 10))
                        
                        Toggle(isOn: Binding<Bool>(
                            get: { isFavorite },
                            set: { newValue in
                                isFavorite = newValue
                            }
                        )) {
                            Text("Es favorita")
                        }
                    }
                    .frame(width: 420, height: 440)
                    
                    HStack() {
                        Button("Cancelar") {
                            close()
                        }
                        
                        Button(orgToEdit == nil ? "Acceder" : "Guardar") {
                            if let org = orgToEdit {
                                // Edit Mode
                                var updatedOrg = org
                                updatedOrg.label = label
                                updatedOrg.alias = alias
                                updatedOrg.orgType = orgType
                                updatedOrg.isFavorite = isFavorite
                                
                                authenticatedOrgManager.updateOrg(org: updatedOrg)
                                
                                close()
                            } else {
                                // Create Mode
                                isAuthenticating = true
                                authenticate()
                            }
                        }
                        .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines) == "" || alias.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                        .padding()
                    }
                }
                .padding()
            }
            
            if isAuthenticating {
                VStack {
                    ProgressView()
                    Text("Iniciando sesión...")
                        .padding(.top, 10)
                    Text("La ventana se cerrará automáticamente al finalizar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 480, height: 520)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            self.thisWindow = NSApp.keyWindow
            windowDelegate.isAuthenticating = self.isAuthenticating
            windowDelegate.onCancel = {
                self.authenticationCancelled = true
            }
            self.thisWindow?.delegate = windowDelegate
            hideWindowButtons()
        }
        .onChange(of: isAuthenticating) { newValue in
            windowDelegate.isAuthenticating = newValue
        }
    }
    
    func authenticate() {
        authenticationCancelled = false
        isAuthenticating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let cli = SalesforceCLI()
            let instanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL
            
            print("Calling cli.auth with alias: \(alias), instanceUrl: \(instanceUrl), orgType: \(orgType)")
            let authenticated = cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
            
            DispatchQueue.main.async {
                if authenticationCancelled {
                    return
                }
                
                if (authenticated) {
                    print("Authenticated org with alias: \(alias)")
                    let org = cli.orgDetails(alias: alias)
                    
                    print("-------\(org?.id)")
                    
                    let userInfo: [String: Any] = ["orgId": org?.id, "instanceUrl": org?.instanceUrl, "label": label, "alias": alias, "orgType": orgType]
                    close()
                    
                    NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: userInfo)
                    let content = UNMutableNotificationContent()
                    content.title = "Autenticación exitosa"
                    content.body = "Se ha autenticado correctamente con el alias \(alias)."
                    content.sound = UNNotificationSound.default
                    
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                } else {
                    isAuthenticating = false
                }
            }
        }
    }
    
    func hideWindowButtons() {
        if let window = thisWindow { // Or iterate through NSApp.shared.windows
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
    }
    
    func close() {
        if let window = thisWindow {
            print("Closing authenticacion window...")
            window.close()
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
