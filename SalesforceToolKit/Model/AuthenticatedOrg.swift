import Foundation

struct AuthenticatedOrg: Codable, Identifiable {
    var id = UUID()
    var alias: String
    var orgType: String // "Producción" or "Desarrollo"
}
