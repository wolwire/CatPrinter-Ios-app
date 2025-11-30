//
//  ContentView.swift
//  CatPrinter
//
//  Created by Mayank Agrawal on 30/11/25.
//

import PhotosUI
import SwiftUI

struct AlgorithmPreview: Identifiable {
  let id = UUID()
  let name: String
  let image: Image
}

struct ContentView: View {
  @State private var selectedItem: PhotosPickerItem?
  @State private var uiImage: UIImage?
  // Only need a single processed preview (Atkinson)
  @State private var previewImage: UIImage?
  // Image adjustment controls
  @State private var contrast: Double = 1.0  // 0.5..2.0
  @State private var brightness: Double = 0.0  // -1.0..1.0 (CI uses -1..1)
  // Energy for printer (0x0000..0xffff)
  @State private var energyValue: Int = 0xffff
  // Algorithm selection: "atkinson" or "floyd-steinberg"
  @State private var algorithm: String = "atkinson"
  @State private var showingAlert = false
  @State private var alertMessage = ""

  let processor = ImageProcessor()
  @StateObject var printer = PrinterManager()
  @State private var showingPrinterSheet = false

  var body: some View {
    return NavigationView {
      VStack(spacing: 16) {
        if let img = uiImage {
          Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 240)
            .cornerRadius(8)
            .shadow(radius: 4)
        } else {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 240)
            .overlay(Text("No image selected").foregroundColor(.secondary))
        }

        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
          Label("Select Image", systemImage: "photo")
        }
        .onChange(of: selectedItem) { newValue in
          Task {
            guard let item = newValue else { return }
            if let data = try? await item.loadTransferable(type: Data.self) {
              if let img = UIImage(data: data) {
                uiImage = img
                await generatePreview()
              }
            }
          }
        }

        // Controls: contrast, brightness, energy
        if uiImage != nil {
          // Algorithm picker
          Picker("Algorithm", selection: $algorithm) {
            Text("Atkinson").tag("atkinson")
            Text("Floyd–Steinberg").tag("floyd-steinberg")
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)
          .onChange(of: algorithm) { _ in Task { await generatePreview() } }

          VStack(spacing: 8) {
            HStack {
              VStack(alignment: .leading) {
                Text("Contrast: \(String(format: "%.2f", contrast))")
                  .font(.caption)
                Slider(value: $contrast, in: 0.5...2.0, step: 0.01)
                  .onChange(of: contrast) { _ in Task { await generatePreview() } }
              }
              VStack(alignment: .leading) {
                Text("Brightness: \(String(format: "%.2f", brightness))")
                  .font(.caption)
                Slider(value: $brightness, in: -1.0...1.0, step: 0.01)
                  .onChange(of: brightness) { _ in Task { await generatePreview() } }
              }
            }

            HStack {
              Text("Energy:")
              Slider(
                value: Binding(
                  get: {
                    Double(self.energyValue)
                  },
                  set: { newVal in
                    self.energyValue = Int(newVal)
                  }), in: 0...65535, step: 1)
              Text(String(format: "0x%04X", energyValue))
                .font(.caption)
                .frame(width: 80, alignment: .trailing)
            }
          }
          .padding(.horizontal)

          // Show single preview for selected algorithm
          if let pimg = previewImage {
            VStack(spacing: 10) {
              Image(uiImage: pimg)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .border(Color.black, width: 1)

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
                  Task {
                    await printPreview(named: algorithm)
                  }
                }
                .buttonStyle(.bordered)
              }
            }
            .padding(.horizontal)
          }
          HStack {
            Button(action: {
              showingPrinterSheet = true
              printer.startScan()
            }) {
              Label("Select Printer", systemImage: "printer")
            }
            .buttonStyle(.bordered)

            if printer.isConnected {
              Text("Connected: \(printer.connectedPrinterName ?? "?")")
                .font(.footnote)
                .foregroundColor(.green)
            }
          }

          Spacer()
        }  // end if uiImage != nil
      }  // end VStack
      .navigationTitle("Cat Printer")
      .alert(isPresented: $showingAlert) {
        Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
      }
    }  // end NavigationView
    .sheet(isPresented: $showingPrinterSheet) {
      NavigationView {
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
                Button("Connect") {
                  Task {
                    do {
                      try await printer.connectToPeripheral(p.peripheral)
                      showingPrinterSheet = false
                    } catch {
                      alertMessage = "Connection failed: \(error.localizedDescription)"
                      showingAlert = true
                    }
                  }
                }
                .buttonStyle(.bordered)
              }
            }
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Stop") {
              printer.stopScan()
              showingPrinterSheet = false
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Refresh") { printer.startScan() }
          }
        }
        .navigationTitle("Select Printer")
      }
    }
  }

  func generatePreviews() {
    // unused - replaced by single-atkinson preview function
  }

  @MainActor
  func generatePreview() async {
    guard let source = uiImage else { return }
    do {
      // First apply contrast/brightness adjustments
      let adjusted = try processor.applyContrastBrightness(
        uiImage: source, contrast: contrast, brightness: brightness)
      if let img = try processor.preview(uiImage: adjusted, algorithm: algorithm) {
        previewImage = img
      }
    } catch {
      alertMessage = "Failed to generate preview: \(error.localizedDescription)"
      showingAlert = true
    }
  }

  // Rotate helpers (90° increments)
  func rotateLeft() {
    guard let source = uiImage else { return }
    uiImage = source.rotated(byDegrees: -90)
    Task { await generatePreview() }
  }

  func rotateRight() {
    guard let source = uiImage else { return }
    uiImage = source.rotated(byDegrees: 90)
    Task { await generatePreview() }
  }

  @MainActor
  func printPreview(named name: String) async {
    guard let source = uiImage else { return }
    do {
      // Apply adjustments before printing
      let adjusted = try processor.applyContrastBrightness(
        uiImage: source, contrast: contrast, brightness: brightness)
      guard let bin = try processor.binarizeForPrint(uiImage: adjusted, algorithm: name) else {
        alertMessage = "Unable to binarize image for \(name)"
        showingAlert = true
        return
      }
      // Build commands
      let data = try printer.cmdsPrintImage(img: bin, energy: energyValue)
      // Send via BLE
      try await printer.send(data: data)
      alertMessage = "Print job sent"
      showingAlert = true
    } catch {
      alertMessage = "Error: \(error.localizedDescription)"
      showingAlert = true
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
