import Foundation

struct AuthenticatedOrg: Codable, Identifiable {
    var id = UUID()
    var alias: String
    var label: String
    var orgId: String? = ""
    var instanceUrl: String? = ""
    var orgType: String // "Producción" or "Desarrollo"
    var sandboxType: String? = "sandbox"
    var isFavorite: Bool? = false
    var isDefault: Bool? = false
    var useBrowser: String? = "default"
}
