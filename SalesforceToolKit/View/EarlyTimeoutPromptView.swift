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

            Text("Esto está tardando más de lo esperado")
                .font(.title2)
                .padding(.bottom, 5)

            Text("El proceso de exploración de su organización está tardando más de 10 segundos. ¿Desea reintentar o cancelar?")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)

            HStack {
                Button("Cancelar") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction) // Para el comportamiento estándar de cancelar

                Button("Reintentar") {
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
