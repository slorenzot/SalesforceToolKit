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
            return("\(error.localizedDescription): \(launchPath)", 1)
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
    
    func auth(alias: String, instanceUrl: String? = nil, orgType: String) {
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