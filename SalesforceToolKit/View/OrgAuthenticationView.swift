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
                onCancel?() // This will set `authenticationCancelled = true` in AuthenticationView and stop UI timer
                return true
            } else {
                return false
            }
        }
        return true
    }
}

struct OrgAuthenticationView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var orgToEdit: AuthenticatedOrg?
    
    let timer = 120 // seconds
    
    @State private var orgType: String
    @State private var label: String
    @State private var alias: String
    @State private var isFavorite: Bool = false
    @State private var isAuthenticating = false
    @State private var authenticationCancelled = false // Tracks if user or timeout cancelled
    @State private var windowDelegate = AuthenticationWindowDelegate()
    @State private var thisWindow: NSWindow?
    
    // Timer specific states
    @State private var elapsedSeconds: Int = 0
    @State private var showEarlyTimeoutPrompt: Bool = false
    @State private var uiTimer: Timer?

    // MARK: - Custom URL State
    @State private var useCustomInstanceUrl: Bool
    @State private var customInstanceUrl: String
    // END MARK
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager
    
    let orgTypes = ["Producción", "Desarrollo"]

    init(org: AuthenticatedOrg? = nil) { // Corrected type here
        self.orgToEdit = org
        
        if let org = org {
            _orgType = State(initialValue: org.orgType)
            _label = State(initialValue: org.label)
            _alias = State(initialValue: org.alias)
            _isFavorite = State(initialValue: org.isFavorite ?? false)
            // MARK: - Initialize custom URL states when editing an existing org
            _useCustomInstanceUrl = State(initialValue: org.instanceUrl != nil && ![PRO_AUTH_URL, DEV_AUTH_URL].contains(org.instanceUrl!))
            _customInstanceUrl = State(initialValue: org.instanceUrl ?? "")
            // END MARK
        } else {
            _orgType = State(initialValue: "Producción")
            _label = State(initialValue: "")
            _alias = State(initialValue: "")
            _isFavorite = State(initialValue: false)
            // MARK: - Initialize custom URL states for new org
            _useCustomInstanceUrl = State(initialValue: false)
            _customInstanceUrl = State(initialValue: "")
            // END MARK
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
                        // MARK: - Custom URL Toggle
                        Toggle(isOn: $useCustomInstanceUrl) {
                            Text("Usar URL de Instancia Personalizada")
                        }
                        .onChange(of: useCustomInstanceUrl) { newValue in
                            // Clear custom URL if toggle is switched off
                            if !newValue {
                                customInstanceUrl = ""
                            }
                        }

                        // MARK: - Custom URL TextField
                        if useCustomInstanceUrl {
                            TextField("URL de Instancia:", text: $customInstanceUrl)
                                .disableAutocorrection(true) // URLs generally don't need autocorrection
                        } else {
                            let standardInstanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL
                            // Display selected standard URL for user info when custom is not used
                            TextField("URL de Instancia:", text: .constant(standardInstanceUrl)) // FIX: Use .constant for a disabled TextField
                                .disabled(true) // URLs generally don't need autocorrection
                        }
                        // END MARK
                        
                        TextField("Etiqueta", text: $label)
                            .onChange(of: label, perform: { value in
                                if orgToEdit == nil { // Only generate alias in create mode
                                    alias = generateAlias(from: value)
                                }
                            })
                        
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
                    .frame(width: 420, height: 440) // Adjust height as needed with new fields
                    
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
                                // MARK: - Save custom URL
                                if useCustomInstanceUrl {
                                    updatedOrg.instanceUrl = customInstanceUrl
                                } else {
                                    updatedOrg.instanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL
                                }
                                // END MARK
                                
                                authenticatedOrgManager.updateOrg(org: updatedOrg)
                                
                                close()
                            } else {
                                // Create Mode
                                // isAuthenticating is set to true at the beginning of authenticate()
                                authenticate()
                            }
                        }
                        .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines) == "" || alias.trimmingCharacters(in: .whitespacesAndNewlines) == "" || (useCustomInstanceUrl && customInstanceUrl.trimmingCharacters(in: .whitespacesAndNewlines) == "")) // Disable if custom URL is empty when selected
                        .padding()
                    }
                }
                .padding()
            }
            
            // Show main progress view only if authenticating and not showing the early timeout prompt
            if isAuthenticating && !showEarlyTimeoutPrompt {
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
            
            // Show the early timeout prompt if triggered
            if showEarlyTimeoutPrompt {
                EarlyTimeoutPromptView(
                    onRetry: {
                        stopUITimer() // Detener este temporizador del aviso
                        authenticationCancelled = false // Restablecer la bandera de cancelación para un nuevo intento
                        let cli = SalesforceCLI()
                        cli.killProcess(port: 1717) // Asegurarse de que cualquier proceso CLI anterior se detenga
                        isAuthenticating = false // Ocultar temporalmente todo el progreso para permitir un reinicio limpio de la UI
                        
                        authenticate() // Reiniciar autenticación
                    },
                    onCancel: {
                        stopUITimer() // Detener este temporizador del aviso
                        authenticationCancelled = true // Marcar cancelación
                        let cli = SalesforceCLI()
                        cli.killProcess(port: 1717) // Detener explícitamente el proceso CLI
                        isAuthenticating = false // Ocultar UI de progreso
                        
                        close() // Cerrar la ventana
                    }
                )
                .frame(width: 480, height: 520) // Coincidir con el tamaño del padre
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            self.thisWindow = NSApp.keyWindow
            windowDelegate.isAuthenticating = self.isAuthenticating
            windowDelegate.onCancel = {
                self.authenticationCancelled = true
                self.stopUITimer() // Detener el temporizador de la UI cuando el usuario cancela a través del cierre de la ventana
            }
            self.thisWindow?.delegate = windowDelegate
            hideWindowButtons()
            
            // If we are already authenticating (e.g., re-appearing after another view), start timer
            if isAuthenticating {
                startUITimer()
            }
        }
        .onChange(of: isAuthenticating) { newValue in
            windowDelegate.isAuthenticating = newValue
            if newValue {
                startUITimer()
            } else {
                stopUITimer()
            }
        }
        .onDisappear {
            stopUITimer() // Ensure timer is stopped when the view is no longer active
        }
    }
    
    // MARK: - UI Timer Logic
    private func startUITimer() {
        stopUITimer() // Ensure any existing timer is stopped
        elapsedSeconds = 0
        showEarlyTimeoutPrompt = false

        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isAuthenticating { // Only increment if we are still authenticating
                elapsedSeconds += 1
                if elapsedSeconds >= timer {
                    // Trigger the prompt, but don't stop the underlying auth process yet
                    showEarlyTimeoutPrompt = true
                }
            } else {
                stopUITimer() // If isAuthenticating became false, stop the timer
            }
        }
        // Add timer to common run loop mode to ensure it fires even during other UI events
        if let timer = uiTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func stopUITimer() {
        uiTimer?.invalidate()
        uiTimer = nil
        elapsedSeconds = 0
        showEarlyTimeoutPrompt = false
    }
    
    // MARK: - Authentication Logic with Timeout
    func authenticate() {
        authenticationCancelled = false
        isAuthenticating = true // Show progress UI

        Task { @MainActor in // Use @MainActor to safely update UI-related @State
            let cli = SalesforceCLI()
            // MARK: - Determine instanceUrl based on custom URL toggle
            let instanceUrl = useCustomInstanceUrl && !customInstanceUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? customInstanceUrl : (orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL)
            // END MARK

            var authResult: Bool? = nil // To store the result of the authentication attempt

            do {
                authResult = try await withThrowingTaskGroup(of: Bool?.self) { group in
                    // Task for the actual authentication process
                    group.addTask {
                        // Perform the blocking CLI call on a background thread/queue using Task.detached.
                        return await Task.detached {
                            print("Calling cli.auth with alias: \(await alias), instanceUrl: \(instanceUrl), orgType: \(await orgType)")
                            return await cli.auth(alias: alias, instanceUrl: instanceUrl, orgType: orgType)
                        }.value
                    }

                    // Task for the timeout
                    group.addTask {
                        do {
                            try await Task.sleep(for: .seconds(timer))
                            // If we reach here, the timeout occurred.
                            // Signal cancellation and explicitly kill the CLI process.
                            await MainActor.run { // Ensure state updates and CLI kill are handled safely
                                self.authenticationCancelled = true // Mark cancellation
                                cli.killProcess(port: 1717) // Ensure process is killed
                                self.isAuthenticating = false // Hide progress UI due to timeout
                                // Show an alert for timeout
                                let alert = NSAlert()
                                alert.messageText = "Autenticación Cancelada"
                                alert.informativeText = "El proceso de inicio de sesión ha tardado demasiado y se ha cancelado."
                                alert.addButton(withTitle: "OK")
                                alert.alertStyle = .warning
                                alert.runModal()
                            }
                            return nil // Indicate that timeout occurred
                        } catch is CancellationError {
                            // The sleep task was cancelled by the authentication task finishing first.
                            return nil
                        }
                    }

                    var result: Bool? = nil
                    // Wait for the first task to complete
                    for try await outcome in group {
                        result = outcome
                        group.cancelAll() // Cancel the other task immediately
                        break
                    }
                    return result
                }

                // Now evaluate the result on the MainActor after the TaskGroup completes
                if authenticationCancelled {
                    // This means either the user cancelled via the window delegate or the timeout occurred.
                    // If timeout, an alert was already shown and isAuthenticating was set to false.
                    // If user cancelled, isAuthenticating needs to be reset here.
                    isAuthenticating = false
                    return // Exit early
                }

                if let authenticated = authResult, authenticated {
                    print("Authenticated org with alias: \(alias)")
                    
                    // Fetch org details (also potentially blocking, run in detached task)
                    let org = await Task.detached {
                        return cli.orgDetails(alias: alias)
                    }.value

                    // MARK: - Pass the actual instanceUrl used for authentication
                    let userInfo: [String: Any] = ["orgId": org?.id ?? "", "instanceUrl": instanceUrl, "label": label, "alias": alias, "orgType": orgType]
                    // END MARK
                    
                    // Close the window on successful authentication ss
                    close() // This will implicitly update `isAuthenticating` via `onChange`
                    
                    NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: userInfo)
                    
                    let content = UNMutableNotificationContent()
                    content.title = "Autenticación exitosa"
                    content.body = "Se ha autenticado correctamente con el alias \(alias)."
                    content.sound = UNNotificationSound.default
                    
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    try await UNUserNotificationCenter.current().add(request) // Await notification addition
                    
                } else if authResult == false {
                    // Authentication explicitly failed by CLI, not timeout.
                    isAuthenticating = false // Hide progress UI
                    let alert = NSAlert()
                    alert.messageText = "Autenticación Fallida"
                    alert.informativeText = "No se pudo autenticar con el alias \(alias). Por favor, inténtelo de nuevo."
                    alert.addButton(withTitle: "OK")
                    alert.alertStyle = .critical
                    alert.runModal()
                }
                // If authResult is nil at this point, it means the timeout task returned nil,
                // and that was already handled by setting `authenticationCancelled = true` and showing an alert.
            } catch is CancellationError {
                print("Authentication process Task was cancelled (e.g., parent task cancelled).")
                isAuthenticating = false // Reset state
            } catch {
                print("An unexpected error occurred during authentication: \(error.localizedDescription)")
                isAuthenticating = false // Reset state
                let alert = NSAlert()
                alert.messageText = "Error Inesperado"
                alert.informativeText = "Ocurrió un error inesperado durante la autenticación: \(error.localizedDescription)"
                alert.addButton(withTitle: "OK")
                alert.alertStyle = .critical
                alert.runModal()
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
            // When window closes, `onChange(of: isAuthenticating)` and `windowDelegate.onCancel`
            // should handle the necessary state cleanup if not already done.
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        OrgAuthenticationView()
    }
}

