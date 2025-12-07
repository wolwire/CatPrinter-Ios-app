import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var printer: PrinterManager
  
  // Theme
  let themeColor = Color(red: 0.9, green: 0.9, blue: 0.95) // Soft Gray-Blue

  var body: some View {
      ZStack {
          Color(red: 0.98, green: 0.98, blue: 0.99)
              .ignoresSafeArea()
          
          ScrollView {
              VStack(spacing: 24) {
                  
                  // Header
                  HStack {
                      Text("Settings")
                          .font(.system(size: 32, weight: .bold, design: .rounded))
                          .foregroundColor(.black)
                      Spacer()
                      Image(systemName: "gearshape.fill")
                          .font(.largeTitle)
                          .foregroundColor(themeColor)
                          .opacity(0.5)
                  }
                  .padding(.horizontal)
                  .padding(.top)
                  
                  // PRINTER CARD
                  VStack(alignment: .leading, spacing: 16) {
                      HStack {
                          Image(systemName: "printer.fill")
                              .foregroundColor(.blue)
                          Text("Printer Status")
                              .font(.headline)
                              .foregroundColor(.black)
                      }
                      
                      Divider()
                      
                      HStack {
                          Text("Connection")
                              .foregroundColor(.gray)
                          Spacer()
                          if printer.isConnected {
                              Text("Connected")
                                  .foregroundColor(.green)
                                  .fontWeight(.bold)
                          } else {
                              Text("Disconnected")
                                  .foregroundColor(.red)
                          }
                      }
                      
                      if let name = printer.connectedPrinterName {
                          HStack {
                              Text("Device Name")
                                  .foregroundColor(.gray)
                              Spacer()
                              Text(name)
                                  .foregroundColor(.black)
                          }
                      }
                  }
                  .padding()
                  .background(Color.white)
                  .cornerRadius(20)
                  .shadow(color: Color.black.opacity(0.05), radius: 4)
                  .padding(.horizontal)
                  
                  // APP INFO CARD
                  VStack(alignment: .leading, spacing: 16) {
                      HStack {
                          Image(systemName: "info.circle.fill")
                              .foregroundColor(.purple)
                          Text("Application")
                              .font(.headline)
                              .foregroundColor(.black)
                      }
                      
                      Divider()
                      
                      HStack {
                          Text("Version")
                              .foregroundColor(.gray)
                          Spacer()
                          Text("1.0.0 (Kawaii Edition)")
                              .foregroundColor(.black)
                      }
                      
                      Button {
                          // Placeholder
                      } label: {
                          HStack {
                              Text("Open Helpers")
                              Spacer()
                              Image(systemName: "chevron.right")
                          }
                          .foregroundColor(.black)
                      }
                  }
                  .padding()
                  .background(Color.white)
                  .cornerRadius(20)
                  .shadow(color: Color.black.opacity(0.05), radius: 4)
                  .padding(.horizontal)
                  
                  Spacer()
              }
          }
      }
      .navigationTitle("") // Hide default title
      .navigationBarTitleDisplayMode(.inline)
  }
}
