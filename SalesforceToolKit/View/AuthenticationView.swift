import SwiftUI
import UserNotifications

struct AuthenticationView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var orgToEdit: AuthenticatedOrg?
    
    @State private var orgType: String
    @State private var label: String
    @State private var alias: String
    @State private var isFavorite: Bool = false
    
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
        let newLabel = label.replacingOccurrences(of: " ", with: "-")
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return newLabel.lowercased()
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
    }

    var body: some View {
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
                    .disabled(orgToEdit == nil)
                Text("La etiqueta es el nombre que se mostrará en Salesforce Toolkit para identificar fácilmente las instancias de su organización y puede contener espacios y caracteres especiales")
                    .font(.system(size: 10))
                
                TextField("Alias", text: $alias)
                    .disabled(orgToEdit != nil)
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
                        let cli = SalesforceCLI()
                        let instanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL
                        print("Calling cli.auth with alias: \(alias), instanceUrl: \(instanceUrl), orgType: \(orgType)")
                        let authenticated = cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
                        
                        if (authenticated) {
                            print("Authenticated org with alias: \(alias)")
                            
                            let userInfo: [String: Any] = ["label": label, "alias": alias, "orgType": orgType]
                            NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: userInfo)
                            
                            let content = UNMutableNotificationContent()
                            content.title = "Autenticación exitosa"
                            content.body = "Se ha autenticado correctamente con el alias \(alias)."
                            content.sound = UNNotificationSound.default

                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                            UNUserNotificationCenter.current().add(request)
                            
                            close()
                        }
                    }
                }
                .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines) == "" || alias.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                .padding()
            }
        }
        .frame(width: 480, height: 350)
        .onAppear {
            hideWindowButtons()
        }
    }
    
    func hideWindowButtons() {
        if let window = NSApp.keyWindow { // Or iterate through NSApp.shared.windows
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
    }
    
    func close() {
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
