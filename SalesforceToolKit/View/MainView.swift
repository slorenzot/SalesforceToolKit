import SwiftUI

struct MainView: View {
    
    @State private var orgType = "Producción"
    @State private var label = ""
    @State private var alias = ""
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text(localized("Start Salesforce Toolkit when I log in"))
            }
            
            HStack() {
                VStack() {
                    Text(localized("Settings"))
                        .font(.system(size: 20))
                        .padding(.bottom, 10)
                    
                    Form {
                        Text(localized("Start Salesforce Toolkit when I log in"))
                        Text(localized("Start Salesforce Toolkit when I log in"))
                    }
                    
                }
            }.padding()
        }
        .padding()
        .frame(width: 700, height: 450)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        OrgAuthenticationView()
    }
}
