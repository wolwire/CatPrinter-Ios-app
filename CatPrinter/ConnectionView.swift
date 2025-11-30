import SwiftUI

struct ConnectionView: View {
  @EnvironmentObject var printer: PrinterManager
  @Binding var selectedTab: Int
  @Binding var showingAlert: Bool
  @Binding var alertMessage: String

  var body: some View {
    NavigationView {
      ZStack {
        List {
          Section(header: Text("Discovered Printers")) {
            ForEach(printer.discoveredPrinters) { p in
              HStack {
                VStack(alignment: .leading) {
                  Text(p.name)
                  if let adv = p.advSummary {
                    Text(adv).font(.caption).foregroundColor(.secondary)
                  } else {
                    Text(p.id.uuidString).font(.caption).foregroundColor(.secondary)
                  }
                }
                Spacer()
                if printer.isConnected && printer.connectedPeripheralID == p.id {
                  Button("Disconnect") {
                    printer.disconnect()
                  }
                  .buttonStyle(.bordered)
                  .tint(.red)
                } else {
                  Button("Connect") {
                    Task {
                      do {
                        try await printer.connectToPeripheral(p.peripheral)
                        // Ensure UI shows the human-friendly name immediately
                        DispatchQueue.main.async {
                          printer.isConnected = true
                          printer.connectedPrinterName = p.name
                          selectedTab = 0
                        }
                      } catch {
                        let ns = error as NSError
                        alertMessage = "Connection failed: \(error.localizedDescription) (code: \(ns.code))"
                        showingAlert = true
                        print("Connection error: \(error) ns=\(ns)")
                      }
                    }
                  }
                  .buttonStyle(.bordered)
                }
              }
            }
          }
        }
        // Scanning overlay
        if printer.isScanning {
          Color.black.opacity(0.25).ignoresSafeArea()
          VStack(spacing: 12) {
            ProgressView("Scanning for printers...")
              .progressViewStyle(CircularProgressViewStyle(tint: .blue))
              .foregroundColor(.primary)
            Text("Please wait")
              .font(.caption)
              .foregroundColor(.secondary)
            Button("Stop Scan") {
              printer.stopScan()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 160 / 255, green: 200 / 255, blue: 255 / 255))
          }
          .padding()
          .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
          .shadow(radius: 8)
          .frame(maxWidth: 320)
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          // Stop is enabled only when a scan is running
          Button("Stop") { printer.stopScan() }
            .disabled(!printer.isScanning)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Refresh") { printer.startScan() }
        }
      }
      .navigationTitle("Connection")
      .toolbarBackground(Color.white, for: .navigationBar)
      .toolbarColorScheme(.light, for: .navigationBar)
      .background(Color.white)
    }
  }
}

struct ConnectionView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(PrinterManager())
  }
}
