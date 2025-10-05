import SwiftUI

struct EditAuthenticationView: View {
    var authenticatedOrgManager: AuthenticatedOrgManager

    var org: AuthenticatedOrg
    
    @State private var alias: String
    @State private var orgType: String
    
    init(org: AuthenticatedOrg, manager: AuthenticatedOrgManager) {
        self.org = org
        self.authenticatedOrgManager = manager
        _alias = State(initialValue: org.alias)
        _orgType = State(initialValue: org.orgType)
    }
    
    var body: some View {
        VStack {
            Form {
                Picker("Tipo de Org", selection: $orgType) {
                    Text("Producción").tag("Producción")
                    Text("Desarrollo").tag("Desarrollo")
                }
                
                TextField("Alias", text: $alias)
            }
            
            Button("Save") {
                var updatedOrg = org
                updatedOrg.alias = alias
                updatedOrg.orgType = orgType
                authenticatedOrgManager.updateOrg(org: updatedOrg) {
                    NSApplication.shared.keyWindow?.close()
                }
            }
            .padding()
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
