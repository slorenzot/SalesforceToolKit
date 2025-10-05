import SwiftUI

struct AuthenticationView: View {
    @State private var orgType = "Producción"
    @State private var alias = ""
    
    let PRO_LOGIN_URL = "https://login.salesforce.com"
    let DEV_LOGIN_URL = "https://test.salesforce.com"
    
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
                let cli = SalesforceCLI()
                let instanceUrl = orgType == "Producción" ? PRO_LOGIN_URL : DEV_LOGIN_URL
                cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
