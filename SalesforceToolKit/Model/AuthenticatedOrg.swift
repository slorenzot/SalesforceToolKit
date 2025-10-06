import Foundation

struct AuthenticatedOrg: Codable, Identifiable {
    var id = UUID()
    var orgId: String?
    var alias: String
    var label: String
    var orgType: String // "Producción" or "Desarrollo"
}
