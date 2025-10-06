import Foundation

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
    
    private func killProcess(port: Int) {
        let (lsofOutput, _) = execute(launchPath: "/usr/sbin/lsof", arguments: ["-i", ":\(port)"])
        
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
    
    func auth(alias: String, instanceUrl: String? = nil, orgType: String) {
        killProcess(port: 1717)
        
        let sfPath = getSfPath()
        var arguments = ["org", "login", "web", "--alias", alias]
        if let instanceUrl = instanceUrl {
            arguments.append(contentsOf: ["--instance-url", instanceUrl])
        }
        
        let (output, status) = execute(launchPath: sfPath, arguments: arguments)
        
        if status == 0 {
            print("Successfully authenticated to org with alias: \(alias)")
            NotificationCenter.default.post(name: .didCompleteAuth, object: nil, userInfo: ["alias": alias, "orgType": orgType])
        } else {
            print("Error authenticating to org: \(output ?? "")")
        }
    }
    
    func open(alias: String) {
        let sfPath = getSfPath()
        let (output, status) = execute(launchPath: sfPath, arguments: ["org", "open", "--target-org", alias])
        
        if status != 0 {
            print("Error opening org: \(output ?? "")")
        }
    }
}
