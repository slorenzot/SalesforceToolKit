import SwiftUI

struct AppPreferencesView: View {
    @AppStorage("sfPath") private var sfPath: String = "/usr/local/bin/sf"
    @AppStorage("defaultBrowser") private var defaultBrowser: String = "chrome"

    var body: some View {
        Form {
            VStack {
                Picker("Default browser", selection: $defaultBrowser) {
                    ForEach(["default", "chrome", "edge", "firefox"], id: \.self) {
                        Text($0)
                    }
                }
                TextField("Custom browser", text: $defaultBrowser)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Salesforce CLI Path", text: $sfPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
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
