import Foundation

struct AuthenticatedOrg: Codable, Identifiable {
    var id = UUID()
    var alias: String
    var label: String
    var orgType: String // "Producción" or "Desarrollo"
    var isFavorite: Bool? = false
    var isDefault: Bool? = false
}
