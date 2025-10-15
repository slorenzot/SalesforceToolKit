import SwiftUI
import UserNotifications

struct MainView: View {
    
    @State private var orgType = "Producción"
    @State private var label = ""
    @State private var alias = ""
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("Start Hidden Bar when I log in")
            }
            
            HStack() {
                VStack() {
                    Text("Settings")
                        .font(.system(size: 20))
                        .padding(.bottom, 10)
                    
                    Form {
                        Text("Start Hidden Bar when I log in")
                        Text("Start Hidden Bar when I log in")
                    }
                    
                }
            }.padding()
        }
        .padding()
        .frame(width: 700, height: 450)
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        OrgAuthenticationView()
    }
}
