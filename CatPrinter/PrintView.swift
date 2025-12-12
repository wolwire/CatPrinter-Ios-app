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
    @State private var showZoomModal = false

  var body: some View {
      ZStack {
          // BACKGROUND
          AppDesignSystem.Colors.backgroundLight
              .ignoresSafeArea()
          
          ScrollView {
              AppCardWithPadding {
                  if uiImage != nil {
                      if let pimg = previewImage {
                          Image(uiImage: pimg)
                              .resizable()
                              .scaledToFit()
                              .cornerRadius(AppDesignSystem.CornerRadius.medium)
                              .overlay(
                                RoundedRectangle(cornerRadius: AppDesignSystem.CornerRadius.medium)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                              )
                              .shadow(color: themeColor.opacity(0.2), radius: 10, x: 0, y: 5)
                              .onTapGesture { showZoomModal = true }
                      } else {
                          ProgressView().padding()
                      }
                  } else {
                      AppEmptyState(
                          icon: "photo.on.rectangle.angled",
                          message: "No image selected",
                          iconColor: themeColor
                      )
                  }
              }
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
                              .foregroundColor(themeColor) // Theme color
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
                      VStack(spacing: AppDesignSystem.Spacing.lg) {
                          AppSlider(
                            value: $contrast,
                            in: 0.5...2.0,
                            defaultValue: 1.0,
                            label: "Contrast",
                            color: themeColor,
                            onChange: { Task { await onGeneratePreview() } }
                          )
                          
                          AppSlider(
                            value: $brightness,
                            in: -1...1,
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
                           .foregroundColor(themeColor)
                      }
                      
                      // ROTATION
                      HStack(spacing: AppDesignSystem.Spacing.lg) {
                          Button(action: rotateLeft) {
                              Label("Rotate", systemImage: "rotate.left")
                                  .frame(maxWidth: .infinity)
                                  .foregroundColor(themeColor)
                          }
                          .buttonStyle(AppSecondaryButtonStyle())
                          
                          Button(action: rotateRight) {
                              Label("Rotate", systemImage: "rotate.right")
                                  .frame(maxWidth: .infinity)
                                  .foregroundColor(themeColor)
                          }
                          .buttonStyle(AppSecondaryButtonStyle())
                      }
                      
                      // PRINT BUTTON
                      if printer.isConnected {
                          AppPrintButton {
                              Task { await onPrintPreview(algorithm) }
                          }
                          .padding(.top)
                      } else {
                          Text("Connect a printer to print")
                              .font(.caption)
                              .foregroundColor(AppDesignSystem.Colors.error)
                      }
                  }
              }
              .padding(24)
              .background(Color.white)
              .environment(\.colorScheme, .light) // Forces black text for anything inside
              .cornerRadius(30, corners: [.topLeft, .topRight]) // Sheet look
          }
      }
      .alert(isPresented: $showingAlert) {
        Alert(
          title: Text("Info"),
          message: Text(alertMessage),
          dismissButton: .default(Text("OK"))
        )
      }
      .fullScreenCover(isPresented: $showZoomModal) {
          if let img = previewImage {
              ZoomImageModal(image: img, isPresented: $showZoomModal)
          }
      }
  }
}

// Note: KawaiiSlider and KawaiiSecondaryButtonStyle have been moved to Components/AppSlider.swift and Components/AppButton.swift
