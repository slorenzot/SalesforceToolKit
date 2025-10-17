//
//  Browser.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 17/10/25.
//

import Foundation

struct Browser: Identifiable, Hashable {
    let id = UUID() // Conforme a Identifiable para su uso en ForEach
    let name: String // Nombre amigable para el usuario, ej., "Google Chrome"
    let label: String
    let bundleIdentifier: String // Identificador de paquete único, ej., "com.google.Chrome"
    // Propiedad para el icono del sistema, opcional
}
