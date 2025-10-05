import SwiftUI

struct AppPreferencesView: View {
    @AppStorage("sfPath") private var sfPath: String = "/usr/local/bin/sf"

    var body: some View {
        Form {
            TextField("Salesforce CLI Path", text: $sfPath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .frame(width: 400, height: 100)
    }
}

struct AppPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        AppPreferencesView()
    }
}