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
                .font(.largeTitle)
            Text("Some of this websites or online tools are  from theirs owner and ths credits are for themselves")
            Text("Salesforce")
                .font(.largeTitle)
            Text("Workbench")
                .font(.largeTitle)
            Text("JSON2Apex")
                .font(.largeTitle)
        }
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
