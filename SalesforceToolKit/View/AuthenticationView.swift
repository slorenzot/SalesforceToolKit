import SwiftUI
import UserNotifications

struct AuthenticationView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var orgToEdit: AuthenticatedOrg?
    
    @State private var orgType: String
    @State private var label: String
    @State private var alias: String
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager
    
    let orgTypes = ["Producción", "Desarrollo"]

    init(org: AuthenticatedOrg? = nil) {
        self.orgToEdit = org
        
        if let org = org {
            _orgType = State(initialValue: org.orgType)
            _label = State(initialValue: org.label)
            _alias = State(initialValue: org.alias)
        } else {
            _orgType = State(initialValue: "Producción")
            _label = State(initialValue: "")
            _alias = State(initialValue: "")
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
                    .disabled(orgToEdit != nil)
                TextField("Alias", text: $alias)
                    .disabled(orgToEdit == nil)
            }
            
            Button(orgToEdit == nil ? "Acceder" : "Guardar") {
                if let org = orgToEdit {
                    // Edit Mode
                    var updatedOrg = org
                    updatedOrg.label = label
                    updatedOrg.alias = alias
                    updatedOrg.orgType = orgType
                    authenticatedOrgManager.updateOrg(org: updatedOrg)
                    close()
                } else {
                    // Create Mode
                    print("Acceder button clicked")
                    let cli = SalesforceCLI()
                    let instanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL
                    print("Calling cli.auth with alias: \(alias), instanceUrl: \(instanceUrl), orgType: \(orgType)")
                    let authenticated = cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
                    
                    if (authenticated) {
                        print("Authenticated org with alias: \(alias)")
                        
                        let userInfo: [String: Any] = ["label": label, "alias": alias, "orgType": orgType]
                        NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: userInfo)
                        
                        let content = UNMutableNotificationContent()
                        content.title = "Authentication Successful"
                        content.body = "Successfully authenticated to org \(alias)."
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
        .padding()
        .frame(width: 300, height: 150)
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
