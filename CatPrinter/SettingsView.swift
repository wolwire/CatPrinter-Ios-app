import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var printer: PrinterManager
  @EnvironmentObject var modelManager: ModelManager
  @EnvironmentObject var apiService: ZImageAPIService
  @State private var showAPIConfig = false
  
  // Theme
  let themeColor = Color(red: 0.9, green: 0.9, blue: 0.95) // Soft Gray-Blue

  var body: some View {
      ZStack {
          AppDesignSystem.Colors.backgroundLight
              .ignoresSafeArea()
          
          ScrollView {
              VStack(spacing: 20) {
                  
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
                  
                  // API CONFIGURATION CARD
                  VStack(alignment: .leading, spacing: 16) {
                      HStack {
                          Image(systemName: "cloud.fill")
                              .foregroundColor(.purple)
                          Text("Cloud Generation")
                              .font(.headline)
                              .foregroundColor(.black)
                      }
                      
                      Divider()
                      
                      VStack(alignment: .leading, spacing: 12) {
                          Text("This app uses zimage-server API for image generation")
                              .font(.caption)
                              .foregroundColor(.gray)
                          
                          HStack {
                              Circle()
                                  .fill(apiService.isConfigured ? Color.green : Color.orange)
                                  .frame(width: 8, height: 8)
                              Text(apiService.isConfigured ? "API Configured" : "API Not Configured")
                                  .font(.caption)
                                  .foregroundColor(apiService.isConfigured ? .green : .orange)
                              Spacer()
                              Button("Configure") {
                                  showAPIConfig = true
                              }
                              .font(.caption)
                              .padding(.horizontal, 12)
                              .padding(.vertical, 6)
                              .background(Color.purple.opacity(0.1))
                              .foregroundColor(.purple)
                              .cornerRadius(8)
                          }
                      }
                  }
                  .padding()
                  .background(Color.white)
                  .cornerRadius(20)
                  .shadow(color: Color.black.opacity(0.05), radius: 4)
                  
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
                  
                  Spacer()
              }
              .padding()
          }
          .navigationTitle("Settings")
          .navigationBarTitleDisplayMode(.large)
          .background(AppDesignSystem.Colors.backgroundLight.ignoresSafeArea())
          .sheet(isPresented: $showAPIConfig) {
              NavigationView {
                  APIConfigView()
                      .navigationBarTitleDisplayMode(.inline)
                      .toolbar {
                          ToolbarItem(placement: .navigationBarTrailing) {
                              Button("Done") {
                                  showAPIConfig = false
                              }
                          }
                      }
              }
          }
      }
  }
}