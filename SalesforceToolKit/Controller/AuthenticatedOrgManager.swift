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
    
    func addOrg(alias: String, orgType: String) {
        let newOrg = AuthenticatedOrg(alias: alias, orgType: orgType)
        if !authenticatedOrgs.contains(where: { $0.alias == alias }) {
            authenticatedOrgs.append(newOrg)
            saveOrgs()
        }
    }
    
    func deleteOrg(org: AuthenticatedOrg) {
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs.remove(at: index)
            saveOrgs()
        }
    }
    
    func updateOrg(org: AuthenticatedOrg) {
        if let index = authenticatedOrgs.firstIndex(where: { $0.id == org.id }) {
            authenticatedOrgs[index] = org
            saveOrgs()
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
           let orgType = userInfo["orgType"] as? String {
            addOrg(alias: alias, orgType: orgType)
        }
    }
}

extension Notification.Name {
    static let didCompleteAuth = Notification.Name("didCompleteAuth")
}