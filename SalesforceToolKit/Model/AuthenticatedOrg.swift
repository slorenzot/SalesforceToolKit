import Foundation

enum OrgType {
    case Production
    case Sandbox
}

enum SandboxType {
    case SIT
    case UAT
}

struct AuthenticatedOrg: Codable, Identifiable {
    var id = UUID()
    var alias: String
    var label: String
    var orgType: String // "Producción" or "Desarrollo"
    var isFavorite: Bool? = false
    var isDefault: Bool? = false
    var useBrowser: String? = "default"
}
