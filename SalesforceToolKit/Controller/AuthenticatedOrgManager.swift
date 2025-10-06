import Foundation

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
    
    func addOrg(label: String, alias: String, orgType: String, orgId: String) {
        let newOrg = AuthenticatedOrg(orgId: orgId, alias: alias, label: label, orgType: orgType)
        if !authenticatedOrgs.contains(where: { $0.alias == alias }) {
            authenticatedOrgs.append(newOrg)
            saveOrgs()
        }
    }
    
    func logoutOrg(org: AuthenticatedOrg) -> Bool {
        let cli = SalesforceCLI()
        let deleted = cli.logout(alias: org.alias)
        
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs.remove(at: index)
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
            saveOrgs()
            
            return deleted
        }
        
        return false
    }
    
    func updateOrg(org: AuthenticatedOrg, completion: (() -> Void)? = nil) {
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs[index] = org
            saveOrgs()
            completion?()
        }
    }
    
    private func saveOrgs() {
        if let encoded = try? JSONEncoder().encode(authenticatedOrgs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadOrgs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([AuthenticatedOrg].self, from: data) {
                authenticatedOrgs = decoded
            }
        }
    }
    
    @objc private func handleSuccessfulAuth(notification: Notification) {
        if let userInfo = notification.userInfo,
           let alias = userInfo["alias"] as? String,
           let orgType = userInfo["orgType"] as? String,
           let orgId = userInfo["orgId"] as? String {
            addOrg(label: alias, alias: alias, orgType: orgType, orgId: orgId)
        }
    }
}

extension Notification.Name {
    static let didCompleteAuth = Notification.Name("didCompleteAuth")
}
