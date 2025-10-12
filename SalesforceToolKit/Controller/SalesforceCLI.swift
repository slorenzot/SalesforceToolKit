import Foundation
import AppKit

struct OrgDetails: Codable {
    let result: OrgDetailsResult
}

struct OrgDetailsResult: Codable {
    let id: String
    let alias: String
    let apiVersion: String
    let username: String
    let instanceUrl: String
    let clientId: String
    let connectedStatus: String
}

// MARK: - New Org Limits structures
struct OrgDetailLimits: Codable {
    let status: Int
    let result: [OrgLimitItem]
    let warnings: [String]? // Se hace opcional ya que podría estar vacío o no siempre presente
}

struct OrgLimitItem: Codable, Identifiable { // Se añadió Identifiable para su uso en SwiftUI (ej. Table)
    let id = UUID() // Proporciona un ID único para cada elemento, requerido por Table
    let name: String
    let max: Int
    let remaining: Int
}
// END MARK

struct cliInfo: Codable {
    let result: cliInfoResult
}

struct cliInfoResult: Codable {
    let architecture: String
    let cliVersion: String
    let nodeVersion: String
}

class SalesforceCLI {
    func openUrl(url: String) -> Bool {
        // using OAuth token
        // http://[instance].salesforce.com/secur/frontdoor.jsp?sid=[access token]&retURL=[start page]
        // https://sfdcblogger.in/2023/03/09/open-salesforce-org-using-session-id-or-access-token/?i=1
        
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        
        return true
    }
    
    private func getSfPath() -> String {
        // Default to /usr/local/bin/sf if not set
        return UserDefaults.standard.string(forKey: "sfPath") ?? "/usr/local/bin/sf"
    }

    private func execute(launchPath: String, arguments: [String]) -> (String?, Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
        } catch {
            return ("\(error.localizedDescription): \(launchPath)", 1)
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
    
    // MARK: - limits function modified to return OrgDetailLimits?
    func limits(alias: String) -> OrgDetailLimits? {
        let sfPath = getSfPath()
        let arguments = ["org", "limits", "--target-org", alias, "--json"] // Argumentos correctos
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        print("Obteniendo límites de la organización por alias: \(alias)")
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos

        if status == 0, let data = output?.data(using: .utf8) {
            do {
                let limits = try JSONDecoder().decode(OrgDetailLimits.self, from: data) // Decodifica al nuevo tipo
                print(limits)
                
                return limits
            } catch {
                print("Error decodificando límites de la organización: \(error)") // Mensaje de registro correcto
            }
        }
        
        return nil
    }
    // END MARK
    
    func orgDefault(alias: String) -> Bool {
        let sfPath = getSfPath()
        let arguments = ["config", "set", "target-org", alias, "--global"]
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        print("Estableciendo organización por defecto con alias: \(alias)")
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos

        if status != 0 {
            print("Error al establecer la organización por defecto: \(output ?? "")") // Mensaje de registro corregido
            
            return false
        }
        
        print("Organización por defecto establecida exitosamente: \(output ?? "")") // Mensaje de registro corregido
        
        return true
    }
    
    func orgDetails(alias: String) -> OrgDetailsResult? {
        let sfPath = getSfPath()
        let arguments = ["org", "display", "--target-org", alias, "--json"]
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        print("Obteniendo detalles de la organización por alias: \(alias)")
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos

        if status == 0, let data = output?.data(using: .utf8) {
            do {
                let details = try JSONDecoder().decode(OrgDetails.self, from: data)
                print(details)
                
                return details.result
            } catch {
                print("Error decodificando detalles de la organización: \(error)")
            }
        }
        
        return nil
    }
    
    func killProcess(port: Int) {
        let (lsofOutput, _) = execute(launchPath: "/usr/sbin/lsof", arguments: ["-i", ":\(port)"])
        
        print("Matando proceso con PID en puerto: \(port)") // Mensaje de registro corregido
        
        guard let output = lsofOutput else {
            return
        }
        
        let lines = output.split(separator: "\n")
        if lines.count > 1 {
            let line = lines[1]
            let components = line.split(whereSeparator: { $0.isWhitespace })
            if components.count > 1 {
                let pid = String(components[1])
                let (killOutput, _) = execute(launchPath: "/bin/kill", arguments: ["-9", pid])
                print("Proceso con PID \(pid) usando el puerto \(port) eliminado. Salida: \(killOutput ?? "")") // Mensaje de registro corregido
            }
        }
    }
    
    func auth(alias: String, instanceUrl: String? = nil, orgType: String) -> Bool {
        killProcess(port: 1717)
        
        let sfPath = getSfPath()
        var arguments = ["org", "login", "web", "--alias", alias]
        
        if let instanceUrl = instanceUrl {
            arguments.append(contentsOf: ["--instance-url", instanceUrl])
        }
        
        print("Autenticando organización por alias: \(alias)")
        print("Usando argumentos: \(arguments)")
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status == 0 {
            print("Autenticación exitosa en la organización con alias: \(alias)")
            
            if let orgDetails = orgDetails(alias: alias) {
                NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: ["alias": alias, "orgType": orgType, "orgId": orgDetails.id, "instanceUrl": orgDetails.instanceUrl])
            } else {
                 NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: ["alias": alias, "orgType": orgType, "orgId": "UNKNOWN", "instanceUrl": "UNKNOWN"])
            }
            
            return true
        } else {
            print("Error al autenticar la organización: \(output ?? "")")
        }
        
        return false
    }
    
    func logout(alias: String) -> Bool {
        let sfPath = getSfPath()
        let arguments = ["org", "logout", "--target-org", alias, "--no-prompt"]
        
        print("Cerrando sesión de la organización por alias: \(alias)") // Mensaje de registro corregido
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status == 0 {
            print("Sesión cerrada exitosamente de la organización con alias: \(alias)") // Mensaje de registro corregido
            // Se eliminó la llamada a orgDetails ya que no es necesaria para la notificación de cierre de sesión
            NotificationCenter.default.post(name: .didCompleteLogout, object: nil, userInfo: ["alias": alias]) // Se asume que .didCompleteLogout existe o se creará
            return true
        } else {
            print("Error al cerrar sesión de la organización: \(output ?? "")") // Mensaje de registro corregido
        }
        
        return false
    }
    
    // Iniciar sesión
    ////servlet/servlet.su?oid=00DO900000DIJfr&suorgadminid=005Hs00000BVy3m&retURL=%2F005%3FisUserEntityOverride%3D1%26retURL%3D%252Fsetup%252Fhome%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3Dhttps%253A%252F%252Fsuracanaldigitalmotos--devbanca.sandbox.my.salesforce-setup.com%26sfdcIFrameHost%3Dweb%26nonce%3D11225f4a2e79083ca494e1211a87d136a0b310dc0604304de52d75c20d374160%26ltn_app_id%3D%26clc%3D1&targetURL=%2Fhome%2Fhome.jsp&/servlet/servlet.su?oid=00DO900000DIJfr&suorgadminid=005Hs00000BVy3m&retURL=%2F005%3FisUserEntityOverride%3D1%26retURL%3D%252Fsetup%252Fhome%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3Dhttps%253A%252F%252Fsuracanaldigitalmotos--devbanca.sandbox.my.salesforce-setup.com%26sfdcIFrameHost%3Dweb%26nonce%3D11225f4a2e79083ca494e1211a87d136a0b310dc0604304de52d75c20d374160%26ltn_app_id%3D%26clc%3D1&targetURL=%2Fhome%2Fhome.jsp&
    ///servlet/servlet.su?oid=00DO900000DIJfr&suorgadminid=005Hs00000BVy3m
    func openAsUser(userId: String, alias: String, path: String = "/home", incognito:Bool = false, browser: String = "chrome") -> Bool {
        let orgId = "00DO900000DIJfr" // Esto está hardcodeado
        let asUserId = "005Hs00000BVy3m" // Esto está hardcodeado
        let LOGIN_AS_PATH =  "https://suracanaldigitalmotos--devbanca.sandbox.my.salesforce-setup.com/servlet/servlet.su?oid=\(orgId)&suorgadminid=\(asUserId)&retURL=%2F005%3FisUserEntityOverride%3D1%26retURL%3D%252Fsetup%252Fhome%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3Dhttps%253A%252F%252Fsuracanaldigitalmotos--devbanca.sandbox.my.salesforce-setup.com%26sfdcIFrameHost%3Dweb%26nonce%3D11225f4a2e79083ca494e1211a87d136a0b310dc0604304de52d75c20d374160%26ltn_app_id%3D%26clc%3D1&targetURL=%2Fhome%2Fhome.jsp&/servlet/servlet.su?oid=00DO900000DIJfr&suorgadminid=005Hs00000BVy3m&retURL=%2F005%3FisUserEntityOverride%3D1%26retURL%3D%252Fsetup%252Fhome%26appLayout%3Dsetup%26tour%3D%26isdtp%3Dp1%26sfdcIFrameOrigin%3Dhttps%253A%252F%252Fsuracanaldigitalmotos--devbanca.sandbox.my.salesforce-setup.com%26sfdcIFrameHost%3Dweb%26nonce%3D11225f4a2e79083ca494e1211a87d136a0b310dc0604304de52d75c20d374160%26ltn_app_id%3D%26clc%3D1&targetURL=%2Fhome%2Fhome.jsp&"
        return openUrl(url: LOGIN_AS_PATH)
    }
    
    
    func open(alias: String, path: String = "", incognito:Bool = false, browser: String = "chrome") -> Bool {
        let sfPath = getSfPath()
        var arguments = ["org", "open", "--target-org", alias]
        
        if (path != "") {
            arguments.append("--path")
            arguments.append(path)
        }
        
        if (incognito == true) {
            arguments.append("--private")
            print("Se pasó el argumento --private, se ignora el argumento --browser...")
        } else {
            if (browser != "default" && ["chrome", "edge", "firefox"].contains(browser)) {
                arguments.append("--browser")
                arguments.append(browser)
            }
        }
        
        print("Abriendo URL de la organización por alias: \(alias)")
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status != 0 {
            print("Error al abrir la organización: \(output ?? "")")
            
            return false
        }
        
        return true
    }

    func delete(alias: String) -> Bool {
        let sfPath = getSfPath()
        let arguments = ["org", "delete", "--target-org", alias, "--no-prompt"] // Corregido a 'delete'
        
        print("Eliminando organización por alias: \(alias)") // Mensaje de registro corregido
        print("Usando argumentos: \(arguments)") // Registro correcto de argumentos
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)

        if status != 0 {
            print("Error al eliminar la organización: \(output ?? "")")
            return false
        }
        
        print("Organización eliminada exitosamente: \(alias). Salida: \(output ?? "")") // Mensaje de éxito añadido
        return true
    }
    
    func update() -> Bool {
        let sfPath = getSfPath()
        let arguments = ["update"]
        
        print("Actualizando Salesforce CLI")
        print("Usando argumentos: \(arguments)")
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)

        if status != 0 {
            print("Error al actualizar CLI: \(output ?? "")")
            return false
        }
        
        print("Salida de la versión: \(output ?? "")")
        
        return true
    }
    
    func version() -> cliInfoResult? {
        let sfPath = getSfPath()
        let arguments = ["version", "--json"]
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        print("Obteniendo versión de CLI")
        print("Usando argumentos: \(arguments)") // Registro de argumentos añadido

        if status == 0, let data = output?.data(using: .utf8) {
            do {
                let details = try JSONDecoder().decode(cliInfo.self, from: data)
                print(details)
                
                return details.result
            } catch {
                print("Error decodificando versión de CLI: \(error)") // Mensaje de registro corregido
            }
        }
        
        return nil

    }
}
// Añade un nombre de notificación personalizado para el cierre de sesión para evitar confusiones con la autenticación.
extension Notification.Name {
    static let didCompleteLogout = Notification.Name("didCompleteLogout")
}
