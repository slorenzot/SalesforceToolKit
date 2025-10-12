//
//  OrgDetailsView.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 11/10/25.
//

import SwiftUI
import UserNotifications

fileprivate class OrgDetailsWindowDelegate: NSObject, NSWindowDelegate {
    // Renombrado de isAuthenticating a isDataLoading para reflejar mejor el propósito de la vista
    var isDataLoading: Bool = false
    var onCancel: (() -> Void)? // Mantener onCancel si es necesario para alguna acción al cerrar ventana durante carga.

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isDataLoading { // Usar isDataLoading
            let alert = NSAlert()
            alert.messageText = "Cancelar carga de información"
            alert.informativeText = "¿Estás seguro de que quieres cerrar la ventana mientras se carga la información de la organización?"
            alert.addButton(withTitle: "Sí, cerrar")
            alert.addButton(withTitle: "No")
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                // Aquí podrías agregar lógica para detener cualquier tarea de carga activa si fuera necesario.
                // Sin embargo, para Task en Swift Concurrency, simplemente la tarea se cancela al destruir la vista.
                onCancel?() 
                return true
            } else {
                return false
            }
        }
        return true
    }
}

struct OrgDetailsView: View {
    let PRO_AUTH_URL = "https://login.salesforce.com"
    let DEV_AUTH_URL = "https://test.salesforce.com"
    
    var org: AuthenticatedOrg? // Keep this as a property to store the initial org

    /*
     Org Description
     ┌──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
     │ KEY              │ VALUE                                                                                                            │
     ├──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
     │ Access Token     │ 00DD6000000VTHv!AQEAQGpRh9Unu2JrtoJ6hL01H9IGXiYV68AZpLZnFx3Aa0DVVh3dunvHjkZY6oLmEu4lwGSNmdm7JD7vN0x.ahNwmri.w6OI │
     │ Alias            │ sura-uat                                                                                                         │
     │ Api Version      │ 65.0                                                                                                             │
     │ Client Id        │ PlatformCLI                                                                                                      │
     │ Connected Status │ Connected                                                                                                      │
     │ Id               │ 00DD6000000VTHvMAO                                                                                               │
     │ Instance Url     │ https://suracanaldigitalmotos--uat.sandbox.my.salesforce.com                                                     │
     │ Username         │ devcb@sura.com.uat                                                                                               │
     └──────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
     */
    @State private var alias: String
    @State private var apiVersion: String
    @State private var clientId: String
    @State private var connectedStatus: String
    @State private var orgId: String
    @State private var instanceUrl: String
    @State private var username: String
    
    // Estado unificado para la carga de datos de la organización y límites
    @State private var isFetching: Bool 
    @State private var orgType: String // e.g., "Producción" or "Desarrollo"
    @State private var label: String // From AuthenticatedOrg
    
    // Eliminadas las propiedades relacionadas con la autenticación interactiva (timer, prompt, cancellation)
    @State private var windowDelegate = OrgDetailsWindowDelegate()
    @State private var thisWindow: NSWindow?
    
    @EnvironmentObject var authenticatedOrgManager: AuthenticatedOrgManager
    
    let orgTypes = ["Producción", "Desarrollo"]

    // MARK: - New State properties for Org Limits
    @State private var orgLimits: [OrgLimitItem] = []
    @State private var selectedTab: String = "Details" // Para la TabView
    // END MARK

    init(org: AuthenticatedOrg? = nil) {
        self.org = org

        if let existingOrg = org {
            // Inicializar con valores de AuthenticatedOrg y marcamos para cargar los detalles completos
            _alias = State(initialValue: existingOrg.alias)
            _apiVersion = State(initialValue: "") // Se cargará asíncronamente
            _clientId = State(initialValue: "") // Se cargará asíncronamente
            _connectedStatus = State(initialValue: "") // Se cargará asíncronamente
            _orgId = State(initialValue: existingOrg.orgId ?? "")
            _instanceUrl = State(initialValue: existingOrg.instanceUrl ?? "")
            _username = State(initialValue: existingOrg.username ?? "")
            _orgType = State(initialValue: existingOrg.orgType)
            _label = State(initialValue: existingOrg.label)
            _isFetching = State(initialValue: true) // Indicar que la carga de datos está en curso
        } else {
            // No hay organización para mostrar, no hay carga de datos
            _alias = State(initialValue: "")
            _apiVersion = State(initialValue: "")
            _clientId = State(initialValue: "")
            _connectedStatus = State(initialValue: "")
            _orgId = State(initialValue: "")
            _instanceUrl = State(initialValue: "")
            _username = State(initialValue: "")
            _isFetching = State(initialValue: false)
            _orgType = State(initialValue: "Producción") // Valor por defecto
            _label = State(initialValue: "N/A") // Valor por defecto
        }
    }

    var body: some View {
        ZStack {
            if isFetching { // Mostrar ProgressView si isFetching es true
                VStack {
                    ProgressView()
                    Text("Obteniendo información de la organización y límites...")
                        .padding(.top, 10)
                    Text("Espere mientras exploramos su organización de Salesforce y organizamos la información.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 480, height: 520)
                .background(Color(NSColor.windowBackgroundColor))
            } else { // Mostrar la TabView una vez que la carga ha terminado
                VStack {
                    // MARK: - TabView para Detalles y Límites
                    TabView(selection: $selectedTab) {
                        // Detalles de la Organización
                        Form {
                            LabeledContent("Etiqueta", value: label)
                            LabeledContent("Alias", value: alias)
                            LabeledContent("ID de Org", value: orgId)
                            LabeledContent("Estado de Conexión", value: connectedStatus)
                            LabeledContent("Usuario", value: username)
                            LabeledContent("URL de Instancia", value: instanceUrl)
                            LabeledContent("Versión de API", value: apiVersion)
                            LabeledContent("ID de Cliente", value: clientId)
                            
                            Picker("Tipo de Org", selection: $orgType) {
                                ForEach(orgTypes, id: \.self) {
                                    Text($0)
                                }
                            }
                        }
                        .padding() // Añade padding al Form mismo
                        .tabItem {
                            Label("Detalles", systemImage: "info.circle.fill")
                        }
                        .tag("Details")

                        // Límites de la Organización
                        Group {
                            // No es necesario isLoadingLimits separado, isFetching lo cubre
                            if orgLimits.isEmpty {
                                Text("No se encontraron límites para la organización o hubo un error al cargarlos.")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                Table(orgLimits) {
                                    TableColumn("Nombre") { item in
                                        Text(item.name)
                                    }
                                    TableColumn("Máximo") { item in
                                        Text("\(item.max)")
                                    }
                                    TableColumn("Restante") { item in
                                        Text("\(item.remaining)")
                                    }
                                }
                                .padding()
                            }
                        }
                        .tabItem {
                            Label("Límites", systemImage: "chart.bar.fill")
                        }
                        .tag("Limits")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Permite que la TabView ocupe el espacio disponible
                    // END MARK
                    
                    HStack() {
                        Button("Cerrar") { // Renombrado de "Cancelar" a "Cerrar"
                            close()
                        }
                    }
                    .padding(.bottom) // Añade padding a los botones
                }
                .padding()
            }
        }
        .frame(width: 480, height: 520)
        .onAppear {
            self.thisWindow = NSApp.keyWindow
            // Actualizar el delegado para que refleje el estado de carga de datos
            windowDelegate.isDataLoading = self.isFetching
            windowDelegate.onCancel = {
                // Aquí puedes agregar lógica si es necesario al cerrar la ventana durante la carga
                // Por ejemplo, para cancelar una operación de red explícitamente, aunque las tareas de Swift Concurrency
                // se cancelan automáticamente cuando su vista desaparece.
            }
            self.thisWindow?.delegate = windowDelegate
            hideWindowButtons()
            
            // Si hay una organización para mostrar y estamos en estado de carga, iniciar la carga de datos
            if self.org != nil && self.isFetching {
                loadOrgData()
            } else if self.org == nil {
                // Si no hay org, aseguramos que no estamos cargando
                self.isFetching = false
            }
        }
        // Eliminado onChange(of: isFetching) y onDisappear relacionados con el timer,
        // ya que la lógica de timer/timeout se ha movido fuera de esta vista.
    }
    
    // MARK: - Función para cargar datos de la organización de forma asíncrona
    private func loadOrgData() {
        Task { @MainActor in
            guard let currentOrgAlias = self.org?.alias else {
                print("Error: Alias de organización no disponible para cargar detalles y límites.")
                self.isFetching = false // No hay alias, no hay nada que cargar
                return
            }

            let cli = SalesforceCLI()
            
            // Cargar Detalles de la Org
            if let fetchedDetails = await Task.detached { cli.orgDetails(alias: currentOrgAlias) }.value {
                self.alias = fetchedDetails.alias
                self.apiVersion = fetchedDetails.apiVersion
                self.clientId = fetchedDetails.clientId
                self.connectedStatus = fetchedDetails.connectedStatus
                self.orgId = fetchedDetails.id
                self.instanceUrl = fetchedDetails.instanceUrl
                self.username = fetchedDetails.username
                // label y orgType ya fueron inicializados desde AuthenticatedOrg en el init
            } else {
                print("Error: No se pudieron cargar los detalles de la organización para el alias: \(currentOrgAlias)")
                // Podrías mostrar una alerta aquí si la falla en la carga de detalles es crítica.
            }

            // Cargar Límites de la Org
            if let fetchedLimits = await Task.detached { cli.limits(alias: currentOrgAlias) }.value {
                self.orgLimits = fetchedLimits.result
            } else {
                print("Error: No se pudieron cargar los límites de la organización para el alias: \(currentOrgAlias)")
                // Podrías mostrar una alerta aquí si la falla en la carga de límites es crítica.
            }

            // Una vez que ambas operaciones (o intentos) han finalizado, ocultar el indicador de carga.
            self.isFetching = false
        }
    }
    // END MARK - Eliminadas todas las funciones relacionadas con el timer y authenticate()

    func hideWindowButtons() {
        if let window = thisWindow { // Or iterate through NSApp.shared.windows
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
    }
    
    func close() {
        if let window = thisWindow {
            print("Cerrando ventana de detalles de organización...")
            window.close()
        }
    }
}

struct OrgDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Proporcionar una AuthenticatedOrg de ejemplo para el preview
        OrgDetailsView(org: AuthenticatedOrg(alias: "mock-org", label: "Mock Org Label", orgId: "00DMock", instanceUrl: "https://mock.salesforce.com", orgType: "Desarrollo"))
            .environmentObject(AuthenticatedOrgManager()) // Proporcionar un manager para el preview
    }
}
