import SwiftUI

struct AuthenticationView: View {
    @State private var orgType = "Producción"
    @State private var alias = ""
    
    let orgTypes = ["Producción", "Desarrollo"]

    var body: some View {
        VStack {
            Form {
                Picker("Tipo de Org", selection: $orgType) {
                    ForEach(orgTypes, id: \.self) {
                        Text($0)
                    }
                }
                
                TextField("Alias", text: $alias)
            }
            
            Button("Acceder") {
                print("Acceder button clicked")
                let cli = SalesforceCLI()
                let instanceUrl = orgType == "Producción" ? "https://login.salesforce.com" : "https://test.salesforce.com"
                print("Calling cli.auth with alias: \(alias), instanceUrl: \(instanceUrl), orgType: \(orgType)")
                cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
            }
            .padding()
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}