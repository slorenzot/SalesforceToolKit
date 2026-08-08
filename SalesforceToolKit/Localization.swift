import Foundation

/// Centralizes access to the application's string catalog.
func localized(_ key: String, _ arguments: CVarArg...) -> String {
    let value = NSLocalizedString(key, comment: "")
    return arguments.isEmpty ? value : String(format: value, arguments: arguments)
}

func localizedOrganizationType(_ value: String) -> String {
    switch value {
    case "Producción":
        return localized("Production")
    case "Desarrollo":
        return localized("Development")
    default:
        return value
    }
}
