import SwiftUI

struct ConnectionView: View {
  @EnvironmentObject var printer: PrinterManager
  @Binding var showingAlert: Bool
  @Binding var alertMessage: String
  
  // Theme Color
  let themeColor = Color(red: 0.6, green: 0.9, blue: 0.7) // Pastel Mint

  var body: some View {
      ZStack {
          // BACKGROUND
          Color(red: 0.98, green: 0.98, blue: 0.99)
              .ignoresSafeArea()
          
          ScrollView {
              VStack(spacing: 30) {
                  
                  // STATUS HEADER
                  VStack(spacing: 16) {
                      ZStack {
                          Circle()
                              .fill(printer.isConnected ? themeColor.opacity(0.1) : Color.red.opacity(0.1))
                              .frame(width: 120, height: 120)
                          
                          Image(systemName: printer.isConnected ? "printer.fill" : "printer.fill.and.paper.fill")
                              .font(.system(size: 48))
                              .foregroundColor(printer.isConnected ? themeColor : .gray)
                      }
                      
                      Text(printer.isConnected ? "Connected to \(printer.connectedPrinterName ?? "Printer")" : "No Printer Connected")
                          .font(.headline)
                          .foregroundColor(.black)
                  }
                  .padding(.top, 40)
                  
                  // SCAN BUTTON
                  Button {
                      printer.startScan()
                  } label: {
                      HStack {
                          Image(systemName: "dot.radiowaves.left.and.right")
                          Text(printer.isScanning ? "Scanning..." : "Scan for Printers")
                      }
                      .font(.headline)
                      .foregroundColor(.black.opacity(0.8))
                      .frame(width: 200, height: 50)
                      .background(printer.isScanning ? Color.gray : themeColor)
                      .cornerRadius(25)
                      .shadow(color: themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                  }
                  .disabled(printer.isScanning)
                  
                  
                  // LIST
                  if !printer.discoveredPrinters.isEmpty || printer.isConnected {
                      VStack(alignment: .leading, spacing: 16) {
                          Text("Devices")
                              .font(.subheadline)
                              .foregroundColor(.gray)
                              .padding(.horizontal)
                          
                          // Connected
                          if let p = printer.connectedPrinter {
                              PrinterBubble(p: p, isConnected: true, themeColor: themeColor, showingAlert: $showingAlert, alertMessage: $alertMessage)
                          }
                          
                          // Discovered
                          ForEach(printer.discoveredPrinters) { item in
                              if item.name != printer.connectedPrinter?.name {
                                  PrinterBubble(p: item, isConnected: false, themeColor: themeColor, showingAlert: $showingAlert, alertMessage: $alertMessage)
                              }
                          }
                      }
                      .padding()
                  } else {
                      Spacer()
                      Text("Tap scan to find nearby printers")
                          .font(.caption)
                          .foregroundColor(.gray)
                      Spacer()
                  }
              }
          }
      }
  }
}

struct PrinterBubble: View {
    let p: PrinterManager.DiscoveredPrinter
    let isConnected: Bool
    let themeColor: Color
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    @EnvironmentObject var printer: PrinterManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(p.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(p.id.uuidString)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            
            if isConnected {
                Button("Disconnect") {
                    printer.disconnect()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            } else {
                Button("Connect") {
                    connectTo(p: p)
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeColor)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func connectTo(p: PrinterManager.DiscoveredPrinter) {
      Task {
        do {
            try await printer.connectToPeripheral(p: p)
          DispatchQueue.main.async {
            printer.isConnected = true
            printer.connectedPrinterName = p.name
            printer.connectedPeripheralID = p.id
            printer.connectedPrinter = p
          }
        } catch {
            let ns = error as NSError
            alertMessage = "Connection failed: \(error.localizedDescription) (code: \(ns.code))"
            showingAlert = true
        }
      }
    }
}
