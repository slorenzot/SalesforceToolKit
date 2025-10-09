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
                Picker("Navegador por defecto", selection: $defaultBrowser) { // Changed string to Spanish
                    ForEach(["default", "chrome", "edge", "firefox"], id: \.self) {
                        Text($0.capitalized) // Capitalize browser names for display
                    }
                }
                .padding(.bottom, 5) // Add some spacing
                
                TextField("Navegador personalizado (ej: /Applications/Brave Browser.app)", text: $defaultBrowser) // Changed string to Spanish
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                TextField("Ruta de Salesforce CLI", text: $sfPath) // Changed string to Spanish
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                // New: Toggle for biometric authentication
                if isTouchIDAvailable {
                    Toggle("Habilitar autenticación biométrica", isOn: $biometricAuthenticationEnabled)
                        .toggleStyle(.checkbox)
                        .padding(.top, 5)
                } else {
                    Text("Autenticación biométrica no disponible en este dispositivo.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 180) // Adjusted height to accommodate new controls
    }
}

struct AppPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide dummy bindings for preview
        AppPreferencesView(biometricAuthenticationEnabled: .constant(false), isTouchIDAvailable: true)
    }
}
