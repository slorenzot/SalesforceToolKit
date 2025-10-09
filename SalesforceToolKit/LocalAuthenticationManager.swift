import Foundation
import LocalAuthentication
import SwiftUI // Required for @Published

/// A manager class to handle local authentication (Touch ID/Face ID).
class LocalAuthenticationManager: ObservableObject {
    /// Indicates if the user has been successfully authenticated.
    @Published var isAuthenticated: Bool = false
    /// Stores any error that occurred during biometric authentication.
    @Published var authenticationError: LAError? = nil

    private var context = LAContext()

    init() {
        // Check biometric availability when the manager is initialized.
        checkBiometricsAvailability()
    }

    /// Checks if biometric authentication is available on the device.
    func checkBiometricsAvailability() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            print("Biometrics available.")
        } else {
            // Biometrics not available or not configured.
            if let laError = error as? LAError {
                print("Biometrics not available: \(laError.localizedDescription)")
                self.authenticationError = laError
            } else {
                print("Biometrics not available: Unknown error")
            }
        }
    }

    /// Attempts to authenticate the user using biometrics.
    /// - Parameters:
    ///   - reason: The localized reason string to display to the user.
    ///   - completion: A closure that is called with `true` if authentication was successful, `false` otherwise.
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        context = LAContext() // Reset context for each authentication attempt

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometrics not available for authentication.")
            self.authenticationError = error as? LAError
            completion(false)
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                self.isAuthenticated = success
                if let laError = error as? LAError {
                    self.authenticationError = laError
                    print("Authentication failed: \(laError.localizedDescription)")
                } else if success {
                    print("Authentication successful.")
                }
                completion(success)
            }
        }
    }
    
    /// A computed property to check if Touch ID is specifically available.
    var isTouchIDAvailable: Bool {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .touchID
        }
        return false
    }
}
