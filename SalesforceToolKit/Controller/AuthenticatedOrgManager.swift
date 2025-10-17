import Foundation
import UserNotifications

class AuthenticatedOrgManager: ObservableObject {
    @Published var authenticatedOrgs: [AuthenticatedOrg] = []
    
    private let userDefaultsKey = "authenticatedOrgs"
    
    init() {
        loadOrgs()
        NotificationCenter.default.addObserver(self, selector: #selector(handleSuccessfulAuth), name: .didCompleteAuth, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addOrg(label: String, alias: String, orgType: String) -> Bool {
        let newOrg = AuthenticatedOrg(alias: alias, label: label, orgType: orgType)
        if !authenticatedOrgs.contains(where: { $0.alias == alias }) {
            authenticatedOrgs.append(newOrg)
            authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
            
            print("Added org with alias (\(alias))")
            saveOrgs()
            return true
        }
        return false
    }
    
    func logoutOrg(org: AuthenticatedOrg) -> Bool {
        let cli = SalesforceCLI()
        let deleted = cli.logout(alias: org.alias)
        
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs.remove(at: index)
            
            print("logout org with alias (\(org.alias))")
            saveOrgs()
            
            return deleted
        }
        
        return false
    }
    
    
    func deleteOrg(org: AuthenticatedOrg) -> Bool {
        let cli = SalesforceCLI()
        let deleted = cli.delete(alias: org.alias)
        
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs.remove(at: index)
            
            print("deleted org with alias (\(org.alias))")
            saveOrgs()
            
            return deleted
        }
        
        return false
    }
    
    func setDefaultOrg(org: AuthenticatedOrg) {
        for i in 0..<authenticatedOrgs.count {
            authenticatedOrgs[i].isDefault = false
        }

        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            if org.isDefault == true {
                let cli = SalesforceCLI()
                let success = cli.orgDefault(alias: org.alias)
                
                if success {
                    authenticatedOrgs[index].isDefault = true
                    print("Updated default org with alias (\(org.alias))")
                }
            }
        }
        saveOrgs()
    }
    
    func updateOrg(org: AuthenticatedOrg, completion: (() -> Void)? = nil) {
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs[index] = org
            authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
            
            print("Updated org with alias (\(org.alias))")
            
            saveOrgs()
            
            completion?()
        }
    }
    
    private func saveOrgs() {
        if let encoded = try? JSONEncoder().encode(authenticatedOrgs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            
            print("Save all orgs with alias...")
        }
    }
    
    private func loadOrgs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([AuthenticatedOrg].self, from: data) {
                authenticatedOrgs = decoded
                authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
                
                print("Loaded orgs (\(authenticatedOrgs.count))")
            }
        }
    }
    
    @objc private func handleSuccessfulAuth(notification: Notification) {
        if let userInfo = notification.userInfo,
           let orgId = userInfo["orgId"] as? String,
           let label = userInfo["label"] as? String,
           let alias = userInfo["alias"] as? String,
           let username = userInfo["username"] as? String,
           let instanceUrl = userInfo["instanceUrl"] as? String,
           let orgType = userInfo["orgType"] as? String {
            let newOrg = AuthenticatedOrg(alias: alias, label: label, orgId: orgId, username: username, instanceUrl: instanceUrl, orgType: orgType)
            if !authenticatedOrgs.contains(where: { $0.alias == alias }) {
                authenticatedOrgs.append(newOrg)
                authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
                
                print("Added org with alias (\(alias))")
                saveOrgs()
            }
        }
    }

    /// Checks if a given alias is already in use by another authenticated organization.
    /// - Parameters:
    ///   - newAlias: The alias to check.
    ///   - currentOrgId: The ID of the organization currently being edited (optional).
    ///                   If provided, the method will ignore the current organization's alias.
    /// - Returns: `true` if the alias is in use by another organization, `false` otherwise.
    func isAliasInUse(newAlias: String, forOrgId currentOrgId: UUID? = nil) -> Bool {
        return authenticatedOrgs.contains { org in
            // Check if the alias matches and if it's a *different* organization
            org.alias == newAlias && (currentOrgId == nil || org.id != currentOrgId)
        }
    }
}

extension AuthenticatedOrgManager {
    /// Imports a list of organizations, adding new ones and skipping duplicates by alias.
    /// - Parameter newOrgs: An array of `AuthenticatedOrg` objects to import.
    func importOrgs(newOrgs: [AuthenticatedOrg]) {
        var addedCount = 0
        var skippedCount = 0

        for newOrg in newOrgs {
            // Check if an organization with the same alias already exists
            if !authenticatedOrgs.contains(where: { $0.alias == newOrg.alias }) {
                authenticatedOrgs.append(newOrg)
                addedCount += 1
            } else {
                skippedCount += 1
            }
        }
        authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
        saveOrgs()
        
        print("Imported \(addedCount) new orgs, skipped \(skippedCount) duplicates.")
        
        // You might want to send a notification here about the import result
        let content = UNMutableNotificationContent()
        if addedCount > 0 || skippedCount > 0 {
            content.title = NSLocalizedString("Importación de Organizaciones Finalizada", comment: "")
            if addedCount > 0 && skippedCount == 0 {
                content.body = String(format: NSLocalizedString("Se importaron %d nuevas organizaciones correctamente.", comment: ""), addedCount)
            } else if addedCount == 0 && skippedCount > 0 {
                content.body = String(format: NSLocalizedString("Se omitieron %d organizaciones ya existentes.", comment: ""), skippedCount)
            } else {
                content.body = String(format: NSLocalizedString("Se importaron %d organizaciones nuevas y se omitieron %d organizaciones existentes.", comment: ""), addedCount, skippedCount)
            }
        } else {
            content.title = NSLocalizedString("Importación de Organizaciones", comment: "")
            content.body = NSLocalizedString("No se encontraron organizaciones válidas para importar en el archivo.", comment: "")
        }
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension Notification.Name {
    static let didCompleteAuth = Notification.Name("didCompleteAuth")
}
