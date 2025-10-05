
//
//  SalesforceCLI.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 22/08/23.
//

import Foundation

class SalesforceCLI {
    
    private func execute(command: String, arguments: [String]) -> (String?, Int32) {
        let task = Process()
        task.launchPath = command
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
    
    func auth(alias: String) {
        let (output, status) = execute(command: "/usr/local/bin/sf", arguments: ["org", "login", "web", "--alias", alias])
        
        if status == 0 {
            print("Successfully authenticated to org with alias: \(alias)")
        } else {
            print("Error authenticating to org: \(output ?? "")")
        }
    }
    
    func open(alias: String) {
        let (output, status) = execute(command: "/usr/local/bin/sf", arguments: ["org", "open", "--target-org", alias])
        
        if status != 0 {
            print("Error opening org: \(output ?? "")")
        }
    }
}
