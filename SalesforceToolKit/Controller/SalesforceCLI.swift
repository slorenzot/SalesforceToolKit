import Foundation

struct OrgDetails: Codable {
    let result: OrgResult
}

struct OrgResult: Codable {
    let id: String
}

class SalesforceCLI {
    
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
    
    private func getOrgDetails(alias: String) -> OrgResult? {
        let sfPath = getSfPath()
        let (output, status) = execute(launchPath: sfPath, arguments: ["org", "display", "--target-org", alias, "--json"])
        
        print("Getting org details by alias: \(alias)")

        if status == 0, let data = output?.data(using: .utf8) {
            do {
                let details = try JSONDecoder().decode(OrgDetails.self, from: data)
                print(details)
                return details.result
            } catch {
                print("Error decoding org details: \(error)")
            }
        }
        return nil
    }
    
    private func killProcess(port: Int) {
        let (lsofOutput, _) = execute(launchPath: "/usr/sbin/lsof", arguments: ["-i", ":\(port)"])
        
        print("Killing process with PID: \(port)")
        
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
                print("Killed process with PID \(pid) using port 1717. Output: \(killOutput ?? "")")
            }
        }
    }
    
    func auth(alias: String, instanceUrl: String? = nil, orgType: String) -> Bool {
        killProcess(port: 1717)
        
        let sfPath = getSfPath()
        var arguments = ["org", "login", "web", "--alias", alias]
        
        print("Authenticating org by alias: \(alias)")
        
        if let instanceUrl = instanceUrl {
            arguments.append(contentsOf: ["--instance-url", instanceUrl])
        }
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status == 0 {
            print("Successfully authenticated to org with alias: \(alias)")
            
            if let orgDetails = getOrgDetails(alias: alias) {
                NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: ["alias": alias, "orgType": orgType, "orgId": orgDetails.id])
            }
            
            return true
        } else {
            print("Error authenticating to org: \(output ?? "")")
        }
        
        return false
    }
    
    func logout(alias: String) -> Bool {
        let sfPath = getSfPath()
        let arguments = ["org", "logout", "--target-org", alias, "--no-prompt"]
        
        print("Logout org by alias: \(alias)")
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status == 0 {
            print("Successfully authenticated to org with alias: \(alias)")
            
            if let orgDetails = getOrgDetails(alias: alias) {
                NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: ["alias": alias, "orgId": orgDetails.id])
            }
            
            return true
        } else {
            print("Error authenticating to org: \(output ?? "")")
        }
        
        return false
    }
    
    func open(alias: String, path: String = "", incognito:Bool = false, browser: String = "chrome") {
        let sfPath = getSfPath()
        var arguments = ["org", "open", "--target-org", alias, "--browser", browser]
        
        if (path != "") {
            arguments.append("--path")
            arguments.append(path)
        }
        
        if (incognito == true) {
            arguments.append("--private")
        }
        
        print("Opening org url by alias: \(alias)")
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status != 0 {
            print("Error opening org: \(output ?? "")")
        }
    }

    func delete(alias: String) -> Bool {
        let sfPath = getSfPath()
        
        print("Deleting org url by alias: \(alias)")
        let (output, status) = execute(launchPath: sfPath, arguments: ["org", "logout", "--target-org", alias, "--no-prompt"])

        if status != 0 {
            print("Error deleting org: \(output ?? "")")
        }
        
        return true
    }
}
