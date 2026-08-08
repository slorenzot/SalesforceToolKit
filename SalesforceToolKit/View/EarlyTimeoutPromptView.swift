//
//  EarlyTimeoutPromptView.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 11/10/25. // Or appropriate date
//

import SwiftUI

struct EarlyTimeoutPromptView: View {
    var onRetry: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            Image(systemName: "hourglass.badge.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .padding(.bottom, 10)

            Text(localized("This is taking longer than expected"))
                .font(.title2)
                .padding(.bottom, 5)

            Text(localized("Loading your organization has taken more than 10 seconds. Would you like to retry or cancel?"))
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)

            HStack {
                Button(localized("Cancel")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction) // Para el comportamiento estándar de cancelar

                Button(localized("Retry")) {
                    onRetry()
                }
                .keyboardShortcut(.defaultAction) // Para el comportamiento estándar de acción predeterminada
            }
            .padding(.top, 20)
        }
    }
}

struct EarlyTimeoutPromptView_Previews: PreviewProvider {
    static var previews: some View {
        EarlyTimeoutPromptView(onRetry: {}, onCancel: {})
    }
}
