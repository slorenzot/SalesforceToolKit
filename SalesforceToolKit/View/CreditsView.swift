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
            Text("Credits to:")
                .font(.title2)
            Text("Some of this websites or online tools are  from theirs owner and ths credits are for themselves")
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
