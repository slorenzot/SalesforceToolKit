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
    
    func addOrg(label: String, alias: String, orgType: String) {
        let newOrg = AuthenticatedOrg(alias: alias, label: label, orgType: orgType)
        if !authenticatedOrgs.contains(where: { $0.alias == alias }) {
            authenticatedOrgs.append(newOrg)
            authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
            
            print("Added org with alias (\(alias))")
            saveOrgs()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSuccessfulAuth), name: .didCompleteAuth, object: nil)
        }
    }
    
    func logoutOrg(org: AuthenticatedOrg) -> Bool {
        let cli = SalesforceCLI()
        let deleted = cli.logout(alias: org.alias)
        
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs.remove(at: index)
            
            print("logout org with alias (\(org.alias))")
            saveOrgs()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSuccessfulAuth), name: .didCompleteAuth, object: nil)
            
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
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSuccessfulAuth), name: .didCompleteAuth, object: nil)
            
            return deleted
        }
        
        return false
    }
    
    func updateOrg(org: AuthenticatedOrg, completion: (() -> Void)? = nil) {
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs[index] = org
            authenticatedOrgs.sort { $0.label.lowercased() < $1.label.lowercased() }
            
            print("updated org with alias (\(org.alias))")
            
            saveOrgs()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSuccessfulAuth), name: .didCompleteAuth, object: nil)
            
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
                
                print("loaded orgs (\(authenticatedOrgs.count))")
            }
        }
    }
    
    @objc private func handleSuccessfulAuth(notification: Notification) {
        if let userInfo = notification.userInfo,
           let label = userInfo["label"] as? String,
           let alias = userInfo["alias"] as? String,
           let orgType = userInfo["orgType"] as? String {
            let _ = addOrg(label: label, alias: alias, orgType: orgType)
        }
    }
}

extension Notification.Name {
    static let didCompleteAuth = Notification.Name("didCompleteAuth")
}
