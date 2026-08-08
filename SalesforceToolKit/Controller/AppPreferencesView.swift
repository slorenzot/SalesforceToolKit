import SwiftUI

struct AppPreferencesView: View {
    @AppStorage("sfPath") private var sfPath: String = "/usr/local/bin/sf"
    @AppStorage("defaultBrowser") private var defaultBrowser: String = "chrome"
    
    // New: Bindings for biometric authentication settings
    @Binding var biometricAuthenticationEnabled: Bool
    var isTouchIDAvailable: Bool // Indicates if Touch ID is hardware-supported

    // New: Initializer to accept bindings
    init(biometricAuthenticationEnabled: Binding<Bool>, isTouchIDAvailable: Bool) {
        self._biometricAuthenticationEnabled = biometricAuthenticationEnabled
        self.isTouchIDAvailable = isTouchIDAvailable
    }

    var body: some View {
        Form {
            VStack(alignment: .leading) { // Changed to VStack for better layout of multiple controls
                Picker(localized("Default browser"), selection: $defaultBrowser) {
                    ForEach(["default", "chrome", "edge", "firefox"], id: \.self) {
                        Text($0.capitalized) // Capitalize browser names for display
                    }
                }
                .padding(.bottom, 5) // Add some spacing
                
                TextField(localized("Custom browser (e.g. /Applications/Chrome.app)"), text: $defaultBrowser)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                TextField(localized("Salesforce CLI path"), text: $sfPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                // New: Toggle for biometric authentication
                if isTouchIDAvailable {
                    Toggle(localized("Enable biometric authentication"), isOn: $biometricAuthenticationEnabled)
                        .toggleStyle(.switch)
                        .padding(.top, 5)
                    Text(localized("Authentication is required to open, modify, log out of, or delete an organization"))
                        .font(.system(size: 11))
                } else {
                    Text(localized("Biometric authentication is not available on this device."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
        }
        .padding()
        .frame(width: 520, height: 480) // Adjusted height to accommodate new controls
    }
}

struct AppPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide dummy bindings for preview
        AppPreferencesView(biometricAuthenticationEnabled: .constant(false), isTouchIDAvailable: true)
    }
}
