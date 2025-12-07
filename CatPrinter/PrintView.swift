import SwiftUI
import PhotosUI

struct PrintView: View {
  @Binding var selectedItem: PhotosPickerItem?
  @Binding var uiImage: UIImage?
  @Binding var previewImage: UIImage?
  @Binding var contrast: Double
  @Binding var brightness: Double
  @Binding var energyValue: Int
  @Binding var algorithm: String
  @Binding var showingAlert: Bool
  @Binding var alertMessage: String

  @EnvironmentObject var printer: PrinterManager
  let themeColor: Color

  let onGeneratePreview: () async -> Void
  let onSelectItem: (PhotosPickerItem?) async -> Void
  let onPrintPreview: (String) async -> Void
  let rotateLeft: () -> Void
  let rotateRight: () -> Void
    
    @StateObject var ocr = OCRViewModel()
    @State private var showScanner = false

  var body: some View {
      ZStack {
          // BACKGROUND
          Color(red: 0.97, green: 0.97, blue: 0.97) // Soft White
              .ignoresSafeArea()
          
          ScrollView {
              VStack(spacing: 24) {
                  
                  // IMAGE CARD
                  VStack {
                      if let img = uiImage {
                          if let pimg = previewImage {
                              Image(uiImage: pimg)
                                  .resizable()
                                  .scaledToFit()
                                  .cornerRadius(12)
                                  .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                  )
                                  .shadow(color: themeColor.opacity(0.2), radius: 10, x: 0, y: 5)
                          } else {
                              ProgressView().padding()
                          }
                      } else {
                          // EMPTY STATE
                          VStack(spacing: 12) {
                              Image(systemName: "photo.on.rectangle.angled")
                                  .font(.system(size: 48))
                                  .foregroundColor(themeColor.opacity(0.5))
                              Text("No image selected")
                                  .font(.subheadline)
                                  .foregroundColor(.secondary)
                          }
                          .frame(height: 200)
                          .frame(maxWidth: .infinity)
                      }
                  }
                  .padding()
                  .background(Color.white)
                  .cornerRadius(20)
                  .shadow(color: Color.black.opacity(0.03), radius: 6)
                  .padding(.horizontal)
                  .padding(.top)

                  // ACTIONS
                  VStack(spacing: 20) {
                      
                      // PICKER
                      PhotosPicker(selection: $selectedItem, matching: .images) {
                          HStack {
                              Image(systemName: "photo.badge.plus")
                              Text("Select Image")
                          }
                          .font(.headline)
                          .foregroundColor(.white)
                          .frame(maxWidth: .infinity)
                          .frame(height: 50)
                          .background(themeColor)
                          .cornerRadius(25)
                          .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                      }
                      .onChange(of: selectedItem) { _, newValue in
                        Task { await onSelectItem(newValue) }
                      }
                      
                      if uiImage != nil {
                          
                          Divider()
                          
                          // ALGORITHM
                          VStack(alignment: .leading) {
                              Text("Style")
                                  .font(.caption)
                                  .bold()
                                  .foregroundColor(.gray) // Explicit gray
                                  .padding(.leading, 4)
                              
                              Picker("Algorithm", selection: $algorithm) {
                                  Text("Atkinson").tag("atkinson")
                                  Text("Floyd–Steinberg").tag("floyd-steinberg")
                              }
                              .pickerStyle(.segmented)
                              .onChange(of: algorithm) { _, al in
                                  Task { await onGeneratePreview() }
                              }
                          }
                          
                          // CONTROLS
                          VStack(spacing: 16) {
                              KawaiiSlider(
                                value: $contrast,
                                range: 0.5...2.0,
                                defaultValue: 1.0,
                                label: "Contrast",
                                color: themeColor,
                                onChange: { Task { await onGeneratePreview() } }
                              )
                              
                              KawaiiSlider(
                                value: $brightness,
                                range: -1...1,
                                defaultValue: 0.0,
                                label: "Brightness",
                                color: themeColor,
                                onChange: { Task { await onGeneratePreview() } }
                              )
                          }
                          
                          // ENERGY (Advanced)
                          HStack {
                             Text("Energy:")
                                  .font(.caption)
                                  .foregroundColor(.gray)
                             Slider(
                               value: Binding(
                                 get: { Double(self.energyValue) },
                                 set: { self.energyValue = Int($0) }
                               ),
                               in: 0...65535,
                               step: 1
                             )
                             .tint(themeColor)
                              
                             Text(String(format: "0x%04X", energyValue))
                               .font(.caption)
                               .monospacedDigit()
                               .foregroundColor(.black)
                          }
                          
                          // ROTATION
                          HStack(spacing: 16) {
                              Button(action: rotateLeft) {
                                  Label("Rotate", systemImage: "rotate.left")
                                      .frame(maxWidth: .infinity)
                                      .foregroundColor(.black)
                              }
                              .buttonStyle(KawaiiSecondaryButtonStyle())
                              
                              Button(action: rotateRight) {
                                  Label("Rotate", systemImage: "rotate.right")
                                      .frame(maxWidth: .infinity)
                                      .foregroundColor(.black)
                              }
                              .buttonStyle(KawaiiSecondaryButtonStyle())
                          }
                          
                          // PRINT BUTTON
                          if printer.isConnected {
                              Button(action: {
                                  Task { await onPrintPreview(algorithm) }
                              }) {
                                  HStack {
                                      Image(systemName: "printer.fill")
                                      Text("PRINT NOW")
                                          .fontWeight(.bold)
                                  }
                                  .foregroundColor(.white)
                                  .frame(maxWidth: .infinity)
                                  .frame(height: 56)
                                  .background(Color.black.opacity(0.8))
                                  .cornerRadius(28)
                                  .shadow(radius: 5)
                              }
                              .padding(.top)
                          } else {
                              Text("Connect a printer to print")
                                  .font(.caption)
                                  .foregroundColor(.red)
                          }
                      }
                  }
                  .padding(24)
                  .background(Color.white)
                  .environment(\.colorScheme, .light) // Forces black text for anything inside
                  .cornerRadius(30, corners: [.topLeft, .topRight]) // Sheet look
              }
          }
      }
      .alert(isPresented: $showingAlert) {
        Alert(
          title: Text("Info"),
          message: Text(alertMessage),
          dismissButton: .default(Text("OK"))
        )
      }
  }
}

// Custom Slider Component with Reset
struct KawaiiSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    let label: String
    let color: Color
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                Spacer()
                
                // Value Display
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(color)
                    
                // Reset Button
                if abs(value - defaultValue) > 0.001 {
                    Button {
                        value = defaultValue
                        onChange()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                }
            }
            Slider(value: $value, in: range, step: 0.01)
                .onChange(of: value) { _, _ in onChange() }
                .tint(color)
        }
    }
}

// Custom Button Styles
struct KawaiiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .cornerRadius(12)
    }
}
