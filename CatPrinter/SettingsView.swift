import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var printer: PrinterManager

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Printer")) {
          Toggle(isOn: Binding(get: { printer.isConnected }, set: { _ in })) {
            Text("Printer connected")
          }
          Text(printer.connectedPrinterName ?? "None").font(.caption)
        }
        Section(header: Text("App")) {
          Text("Version: 0.1")
          Button("Open Python helpers") {
            // placeholder - user can add action later
          }
        }
      }
      .navigationTitle("Settings")
      .toolbarBackground(Color.white, for: .navigationBar)
      .toolbarColorScheme(.light, for: .navigationBar)
      .background(Color.white)
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(PrinterManager())
  }
}
