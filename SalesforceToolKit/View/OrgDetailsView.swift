//
//  OrgDetailsView.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 11/10/25.
//

import SwiftUI
import UserNotifications

fileprivate class OrgDetailsWindowDelegate: NSObject, NSWindowDelegate {
    var isAuthenticating: Bool = false
    var onCancel: (() -> Void)?

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isAuthenticating {
            let alert = NSAlert()
            alert.messageText = "Cancelar exploración de su organización"
            alert.informativeText = "¿Estás seguro de que quieres cancelar el proceso de exploración?"
            alert.addButton(withTitle: "Sí, cancelar")
            alert.addButton(withTitle: "No")
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                let cli = SalesforceCLI()
                cli.killProcess(port: 1717)
                onCancel?() // This will set `authenticationCancelled = true` in AuthenticationView
                return true
            } else {
                return false
            }
        }
        return true
    }
}

struct OrgDetailsView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var orgToEdit: AuthenticatedOrg?
    
    @State private var orgType: String
    @State private var label: String
    @State private var alias: String
    @State private var isFavorite: Bool = false
    @State private var isFetching = true
    @State private var authenticationCancelled = false // Tracks if user or timeout cancelled
    @State private var windowDelegate = OrgDetailsWindowDelegate()
    @State private var thisWindow: NSWindow?
    
    // Timer specific states
    @State private var elapsedSeconds: Int = 0
    @State private var showEarlyTimeoutPrompt: Bool = false
    @State private var uiTimer: Timer?
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager
    
    let orgTypes = ["Producción", "Desarrollo"]

    init(org: AuthenticatedOrg? = nil) { // Corrected type here
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
        let newLabel = label.folding(options: .diacriticInsensitive, locale: .current).replacingOccurrences(of: " ", with: "-")
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return newLabel.lowercased()
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
    }

    var body: some View {
        ZStack {
            if !isFetching {
                VStack {
                    Form {
                        Picker("Tipo de Org", selection: $orgType) {
                            ForEach(orgTypes, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    .frame(width: 420, height: 440)
                    
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
                                // isAuthenticating is set to true at the beginning of authenticate()
                                authenticate()
                            }
                        }
                        .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines) == "" || alias.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                        .padding()
                    }
                }
                .padding()
            }
            
            // Show main progress view only if not showing the early timeout prompt
            if isFetching && !showEarlyTimeoutPrompt {
                VStack {
                    ProgressView()
                    Text("Obteniendo información su organización...")
                        .padding(.top, 10)
                    Text("Espere mientras exploramos su organización de Salesforce y organizamos la información.")
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
                        stopUITimer() // Stop this prompt's timer
                        authenticationCancelled = false // Reset cancellation flag for new attempt
                        // SalesforceCLI().killProcess(port: 1717) // Ensure any previous CLI process is killed
                        isFetching = false // Temporarily hide all progress to allow a clean restart of UI
                        authenticate() // Restart authentication
                    },
                    onCancel: {
                        stopUITimer() // Stop this prompt's timer
                        authenticationCancelled = true // Mark cancellation
                        SalesforceCLI().killProcess(port: 1717) // Explicitly kill CLI process
                        isFetching = false // Hide progress UI
                        close() // Close the window
                    }
                )
                .frame(width: 480, height: 520) // Match the parent size
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            self.thisWindow = NSApp.keyWindow
            windowDelegate.isAuthenticating = self.isFetching
            windowDelegate.onCancel = {
                self.authenticationCancelled = true
                self.stopUITimer() // Stop the UI timer when user cancels via window close
            }
            self.thisWindow?.delegate = windowDelegate
            hideWindowButtons()
            
            // If we are already fetching (e.g., re-appearing after another view), start timer
            if isFetching {
                startUITimer()
            }
        }
        .onChange(of: isFetching) { newValue in
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
            if isFetching { // Only increment if we are still fetching
                elapsedSeconds += 1
                if elapsedSeconds >= 10 {
                    // Trigger the prompt, but don't stop the underlying auth process yet
                    showEarlyTimeoutPrompt = true
                }
            } else {
                stopUITimer() // If isFetching became false, stop the timer
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
        isFetching = true // Show progress UI

        Task { @MainActor in // Use @MainActor to safely update UI-related @State
            let cli = SalesforceCLI()
            let instanceUrl = orgType == "Producción" ? PRO_AUTH_URL : DEV_AUTH_URL

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
                            try await Task.sleep(for: .seconds(30))
                            // If we reach here, the timeout occurred.
                            // Signal cancellation and explicitly kill the CLI process.
                            await MainActor.run { // Ensure state updates and CLI kill are handled safely
                                self.authenticationCancelled = true // Mark cancellation
                                cli.killProcess(port: 1717) // Ensure process is killed
                                self.isFetching = false // Hide progress UI due to timeout
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
                    isFetching = false
                    return // Exit early
                }

                if let authenticated = authResult, authenticated {
                    print("Authenticated org with alias: \(alias)")
                    
                    // Fetch org details (also potentially blocking, run in detached task)
                    let org = await Task.detached {
                        return cli.orgDetails(alias: alias)
                    }.value

                    let userInfo: [String: Any] = ["orgId": org?.id ?? "", "instanceUrl": org?.instanceUrl ?? "", "label": label, "alias": alias, "orgType": orgType]
                    
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
                    isFetching = false // Hide progress UI
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
                isFetching = false // Reset state
            } catch {
                print("An unexpected error occurred during authentication: \(error.localizedDescription)")
                isFetching = false // Reset state
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

struct OrgDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        OrgDetailsView()
    }
}

