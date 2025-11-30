import PhotosUI
import SwiftUI

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
  @Binding var selectedTab: Int

  @EnvironmentObject var printer: PrinterManager
  let themeColor: Color

  let onGeneratePreview: () async -> Void
  let onSelectItem: (PhotosPickerItem?) async -> Void
  let onPrintPreview: (String) async -> Void

  let rotateLeft: () -> Void
  let rotateRight: () -> Void

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        if let img = uiImage {
          Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 240)
            .cornerRadius(8)
            .shadow(radius: 4)
        } else {
          RoundedRectangle(cornerRadius: 20)
            .fill(themeColor.opacity(0.12))
            .frame(height: 240)
            .overlay(Text("No image selected").foregroundColor(.secondary))
            .background(Color.white)
        }

        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
          Label("Select Image", systemImage: "photo")
        }
        .onChange(of: selectedItem) { newValue in
          Task { await onSelectItem(newValue) }
        }

        if uiImage != nil {
          Picker("Algorithm", selection: $algorithm) {
            Text("Atkinson").tag("atkinson")
            Text("Floyd–Steinberg").tag("floyd-steinberg")
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
          .onChange(of: algorithm) { _ in Task { await onGeneratePreview() } }

          VStack(spacing: 8) {
            HStack {
              VStack(alignment: .leading) {
                Text("Contrast: \(String(format: "%.2f", contrast))")
                  .font(.caption)
                Slider(value: $contrast, in: 0.5...2.0, step: 0.01)
                  .onChange(of: contrast) { _ in Task { await onGeneratePreview() } }
              }
              VStack(alignment: .leading) {
                Text("Brightness: \(String(format: "%.2f", brightness))")
                  .font(.caption)
                Slider(value: $brightness, in: -1.0...1.0, step: 0.01)
                  .onChange(of: brightness) { _ in Task { await onGeneratePreview() } }
              }
            }

            HStack {
              Text("Energy:")
              Slider(
                value: Binding(
                  get: { Double(self.energyValue) },
                  set: { newVal in self.energyValue = Int(newVal) }
                ), in: 0...65535, step: 1)
              Text(String(format: "0x%04X", energyValue))
                .font(.caption)
                .frame(width: 80, alignment: .trailing)
            }
          }
          .padding(.horizontal)

          if let pimg = previewImage {
            VStack(spacing: 10) {
              Image(uiImage: pimg)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                .shadow(color: themeColor.opacity(0.12), radius: 8, x: 0, y: 4)

              HStack(spacing: 10) {
                Button(action: rotateLeft) {
                  Label("Rotate Left", systemImage: "rotate.left")
                }
                .buttonStyle(.bordered)

                Button(action: rotateRight) {
                  Label("Rotate Right", systemImage: "rotate.right")
                }
                .buttonStyle(.bordered)

                Button("Print") {
                  Task { await onPrintPreview(algorithm) }
                }
                .buttonStyle(.bordered)
              }
            }
            .padding(.horizontal)
          }

          HStack {
            Button(action: {
              selectedTab = 1
              printer.startScan()
            }) {
              Label("Select Printer", systemImage: "printer.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(themeColor)

            if printer.isConnected {
              Text("Connected: \(printer.connectedPrinterName ?? "?")")
                .font(.footnote)
                .foregroundColor(.green)
            }
          }

          Spacer()
        }
      }
      .navigationTitle("Cat Printer")
      .alert(isPresented: $showingAlert) {
        Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
      }
      .toolbarBackground(Color.white, for: .navigationBar)
      .toolbarColorScheme(.light, for: .navigationBar)
    }
    .background(Color.white)
  }
}

struct PrintView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environmentObject(PrinterManager())
  }
}
