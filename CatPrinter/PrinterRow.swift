import SwiftUI

struct PrinterRow: View {
  var p: PrinterManager.DiscoveredPrinter
  @EnvironmentObject var printer: PrinterManager

  @Binding var showingAlert: Bool
  @Binding var alertMessage: String

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(p.name)

        if let adv = p.advSummary {
          Text(adv)
            .font(.caption)
            .foregroundColor(.secondary)
        } else {
          Text(p.id.uuidString)
            .font(.caption)
            .foregroundColor(.secondary)
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
            connectTo(p: p)
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private func connectTo(p: PrinterManager.DiscoveredPrinter) {
    Task {
      do {
          try await printer.connectToPeripheral(p: p)

        DispatchQueue.main.async {
          printer.isConnected = true
          printer.connectedPrinterName = p.name
          printer.connectedPeripheralID = p.id  // ⭐ Ensure this is set
          printer.connectedPrinter = p
        }

      } catch {
        let ns = error as NSError
        alertMessage = "Connection failed: \(error.localizedDescription) (code: \(ns.code))"
        showingAlert = true
        print("Connection error: \(error) ns=\(ns)")
      }
    }
  }
}
