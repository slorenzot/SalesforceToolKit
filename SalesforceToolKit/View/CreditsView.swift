//
//  CreditsView.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 20/08/23.
//

import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack {
            Text(localized("Credits to:"))
                .font(.title2)
            Text(localized("Some websites and online tools belong to their respective owners; these credits are for them."))
                .padding()
            Text("Salesforce")
                .font(.title2)
                .padding()
            Text("Workbench")
                .font(.title2)
                .padding()
            Text("JSON2Apex")
                .font(.title2)
                .padding()
        }
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
