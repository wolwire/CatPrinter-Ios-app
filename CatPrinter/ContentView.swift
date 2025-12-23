import PhotosUI
import SwiftUI
import UIKit

// MARK: - Models

struct AlgorithmPreview: Identifiable {
  let id = UUID()
  let name: String
  let image: Image
}

enum WorkflowDestination: Hashable {
  case print
  case connect
  case aiTools
  case scanner
  case settings
  case todo
  case banner
  case templates
  case inpainting
  case styleTransfer
}

struct BannerModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
    let imageSystemName: String
}

// MARK: - Constants & Theme

// KawaiiTheme now references the centralized AppDesignSystem
typealias KawaiiTheme = AppDesignSystem.Colors


struct ContentView: View {

  // MARK: - Navigation State
  @State private var path = NavigationPath()

  // MARK: - Image States
  @State private var selectedItem: PhotosPickerItem?
  @State private var uiImage: UIImage?
  @State private var previewImage: UIImage?

  // MARK: - Adjustment Controls
  @State private var contrast: Double = 1.0
  @State private var brightness: Double = 0.0
  @State private var energyValue: Int = 0xffff
  @State private var algorithm: String = "atkinson"

  // MARK: - Alerts
  @State private var showingAlert = false
  @State private var alertMessage = ""

  // MARK: - Printer + UI State
  @StateObject var printer = PrinterManager()
  @State private var showingPrinterSheet = false

  @EnvironmentObject var modelManager: ModelManager
  let processor = ImageProcessor()
  
  // MARK: - Theme State
  @State private var currentAccentColor: Color = KawaiiTheme.pastelBlue
  @State private var bannerSelection = 0
  
  let banners = [
    BannerModel(title: "AI Printer", subtitle: "Create & Print Magic", color: KawaiiTheme.pastelBlue, imageSystemName: "printer.fill"),
    BannerModel(title: "Checklists", subtitle: "Stay organized", color: KawaiiTheme.pastelYellow, imageSystemName: "list.bullet"),
    BannerModel(title: "Banners", subtitle: "Make it big!", color: KawaiiTheme.pastelMint, imageSystemName: "textformat.size"),
    BannerModel(title: "Sweet Notes", subtitle: "Print your thoughts", color: KawaiiTheme.pastelPink, imageSystemName: "heart.fill"),
    BannerModel(title: "Creative Tools", subtitle: "Explore new ideas", color: KawaiiTheme.pastelPurple, imageSystemName: "sparkles")
  ]
  
  let columns = [
      GridItem(.flexible(), spacing: 16),
      GridItem(.flexible(), spacing: 16)
  ]

  var body: some View {
      NavigationStack(path: $path) {
          ZStack(alignment: .top) {
              
              // BACKGROUND (Dynamic Accent)
              currentAccentColor
                  .ignoresSafeArea()
                  .animation(.easeInOut, value: currentAccentColor)
              
              // BACKGROUND (Dynamic Accent)
              currentAccentColor
                  .ignoresSafeArea()
                  .animation(.easeInOut, value: currentAccentColor)
              
              // MAIN SCROLLVIEW (Everything scrolls now)
              ScrollView {
                  VStack(spacing: 0) {
                      
                      // HEADER ("Switch Device")
                      HStack {
                          Button {
                              path.append(WorkflowDestination.connect)
                          } label: {
                              HStack {
                                  Image(systemName: "arrow.triangle.2.circlepath")
                                  Text(printer.isConnected ? (printer.connectedPrinterName ?? "My Printer") : "Switch Device")
                                      .fontWeight(.bold)
                              }
                              .foregroundColor(KawaiiTheme.textDark)
                .foregroundColor(KawaiiTheme.textDark)
                          }
                          
                          Spacer()
                          
Text("+ My Device")
    .foregroundColor(KawaiiTheme.textDark.opacity(0.8))
    .font(.subheadline)
                      }
                      .padding()
                      
                      // BANNER CAROUSEL
                      TabView(selection: $bannerSelection) {
                          ForEach(0..<banners.count, id: \.self) { index in
                              let banner = banners[index]
                              HStack {
                                  VStack(alignment: .leading, spacing: 8) {
Text(banner.title)
    .font(.system(size: 24, weight: .heavy, design: .rounded))
    .foregroundColor(KawaiiTheme.textDark)
Text(banner.subtitle)
    .font(.subheadline)
    .foregroundColor(KawaiiTheme.textDark.opacity(0.8))
                                      
                                      Spacer()
                                  }
                                  Spacer()
                                  Image(systemName: banner.imageSystemName)
                                      .font(.system(size: 80))
                                      .foregroundColor(Color.white.opacity(0.4))
                                      .rotationEffect(.degrees(-15))
                              }
                              .padding(24)
                              .tag(index)
                          }
                      }
                      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                      .frame(height: 180)
                      .onChange(of: bannerSelection) { _, newValue in
                          withAnimation {
                              currentAccentColor = banners[newValue].color
                          }
                      }
                      
                      // WHITE SHEET CONTENT
                      VStack(alignment: .leading, spacing: 20) {
                          
                          // SECTION HEADER
                          HStack {
                              Rectangle()
                                  .fill(currentAccentColor)
                                  .frame(width: 4, height: 16)
                                  .cornerRadius(2)
Text("Create")
    .font(.headline)
    .foregroundColor(currentAccentColor)
                          }
                          .padding(.top, 24)
                          .padding(.horizontal)

                          // GRID
                          LazyVGrid(columns: columns, spacing: 16) {
                              
                              // PRINT
                              KawaiiGridItem(
                                  title: "Photo Print",
                                  icon: "photo.fill",
                                  accentColor: KawaiiTheme.pastelPink,
                                  destination: .print
                              )
                              
                              // SCAN
                              KawaiiGridItem(
                                  title: "Text Scan",
                                  icon: "text.viewfinder",
                                  accentColor: KawaiiTheme.pastelBlue,
                                  destination: .scanner
                              )
                              
                              // AI PAINT (Txt2Img)
                              KawaiiGridItem(
                                  title: "AI Paint",
                                  icon: "paintbrush.fill",
                                  accentColor: KawaiiTheme.pastelYellow,
                                  destination: .aiTools
                              )
                              
                              // AI INPAINTING (Magic Edit)
                              KawaiiGridItem(
                                  title: "Magic Edit",
                                  icon: "wand.and.stars",
                                  accentColor: KawaiiTheme.pastelMint,
                                  destination: .inpainting
                              )
                              
                              // AI STYLE TRANSFER
                              KawaiiGridItem(
                                  title: "Style Transfer",
                                  icon: "paintpalette.fill", // 
                                  accentColor: KawaiiTheme.pastelPurple, // Grouping AI tools with purple
                                  destination: .styleTransfer
                              )
                              
                              // TEMPLATES
                              KawaiiGridItem(
                                  title: "Templates",
                                  icon: "square.dashed",
                                  accentColor: KawaiiTheme.pastelYellow,
                                  destination: .templates
                              )
                          }
                          .padding(.horizontal)
                          
                          
                          // SECTION HEADER: OTHERS
                          HStack {
                              Rectangle()
                                  .fill(currentAccentColor)
                                  .frame(width: 4, height: 16)
                                  .cornerRadius(2)
Text("Other")
    .font(.headline)
    .foregroundColor(currentAccentColor)
                          }
                          .padding(.top, 24)
                          .padding(.horizontal)
                          
                          // Extra dummy items to fill space and look cuter
                          LazyVGrid(columns: columns, spacing: 16) {
                              KawaiiGridItem(
                                  title: "Banner",
                                  icon: "photo.on.rectangle.angled",
                                  accentColor: KawaiiTheme.pastelMint,
                                  destination: .banner
                              )
                              
                              KawaiiGridItem(
                                  title: "To Do List",
                                  icon: "list.bullet.clipboard.fill",
                                  accentColor: KawaiiTheme.pastelBlue,
                                  destination: .todo
                              )

                              KawaiiGridItem(
                                  title: "Settings",
                                  icon: "gearshape.fill",
                                  accentColor: Color.gray,
                                  destination: .settings
                              )
                          }
                          .padding(.horizontal)
                          
                          Spacer(minLength: 100)
                      }
                      .background(Color.white)
                      // ROUNDED TOP CORNERS for the white sheet part
                      .cornerRadius(30, corners: [.topLeft, .topRight])
                  }
              }
              .ignoresSafeArea(edges: .bottom) // Make scrollview go to bottom

          }
            .navigationDestination(for: WorkflowDestination.self) { destination in
              // ... SWITCH (Same as before) ...
              switch destination {
              case .print:
                PrintView(
                selectedItem: $selectedItem,
                uiImage: $uiImage,
                previewImage: $previewImage,
                contrast: $contrast,
                brightness: $brightness,
                energyValue: $energyValue,
                algorithm: $algorithm,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage,
                themeColor: .blue,
                onGeneratePreview: { await generatePreview() },
                onSelectItem: { item in await loadSelectedItem(item) },
                onPrintPreview: { algorithmName in await printPreview(named: algorithmName) },
                rotateLeft: { rotateLeft() },
                rotateRight: { rotateRight() }
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Print")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }

              case .connect:
                ConnectionView(
                showingAlert: $showingAlert,
                alertMessage: $alertMessage
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Connect")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }

              case .aiTools:
                CreateView(
                  themeColor: Color.blue,
                  onSendToPrint: { img in
                    self.uiImage = img
                    self.previewImage = nil
                    path = NavigationPath([WorkflowDestination.print])
                    Task { await generatePreview() }
                  }
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("AI Creation")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }

              case .scanner:
                OCRView(onSendToPrint: { img in
                  self.uiImage = img
                  self.previewImage = nil
                  path = NavigationPath([WorkflowDestination.print])
                  Task { await generatePreview() }
                }
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Magic Edit")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }
                  
              case .settings:
                SettingsView()
                  .toolbar {
                    ToolbarItem(placement: .principal) {
                      Text("Settings")
                        .font(.headline)
                        .foregroundColor(currentAccentColor)
                    }
                  }
                      
              case .todo:
                TodoView(onSendToPrint: { img in
                  self.uiImage = img
                  self.previewImage = nil
                  path = NavigationPath([WorkflowDestination.print])
                  Task { await generatePreview() }
                })
              
              case .banner:
                BannerView(onSendToPrint: { img in
                  self.uiImage = img
                  self.previewImage = nil
                  path = NavigationPath([WorkflowDestination.print])
                  Task { await generatePreview() }
                })
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Magic Edit")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }
                  
              case .templates:
                TemplatesView(onSendToPrint: { img in
                  self.uiImage = img
                  self.previewImage = nil
                  path = NavigationPath([WorkflowDestination.print])
                  Task { await generatePreview() }
                })
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Magic Edit")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }
                  
              case .inpainting:
                InpaintingView(
                  themeColor: KawaiiTheme.pastelMint,
                  onSendToPrint: { img in
                    self.uiImage = img
                    self.previewImage = nil
                    path = NavigationPath([WorkflowDestination.print])
                    Task { await generatePreview() }
                  }
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Magic Edit")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }
                  
              case .styleTransfer:
                StyleTransferView(
                  themeColor: KawaiiTheme.pastelPurple,
                  onSendToPrint: { img in
                    self.uiImage = img
                    self.previewImage = nil
                    path = NavigationPath([WorkflowDestination.print])
                    Task { await generatePreview() }
                  }
                )
                .toolbar {
                  ToolbarItem(placement: .principal) {
                    Text("Magic Edit")
                      .font(.headline)
                      .foregroundColor(currentAccentColor)
                  }
                }
              }
            }
      }
      .environmentObject(printer)
  }

  // MARK: - Logic (Unchanged)
  @MainActor
  func loadSelectedItem(_ item: PhotosPickerItem?) async {
    guard let item = item else { return }
    do {
      if let data = try await item.loadTransferable(type: Data.self),
        let image = UIImage(data: data)
      {
        uiImage = image.normalizedImage()
        previewImage = nil
        await generatePreview()
        return
      }
      alertMessage = "Unable to decode selected image."
      showingAlert = true
    } catch {
      alertMessage = "Failed to load image: \(error.localizedDescription)"
      showingAlert = true
    }
  }

  func generatePreview() async {
    guard let source = uiImage else { return }
    do {
      let adjusted = try processor.applyContrastBrightness(
        uiImage: source, contrast: contrast, brightness: brightness)

      if let img = try processor.preview(uiImage: adjusted, algorithm: algorithm) {
        previewImage = img
      } else {
        previewImage = nil
      }
    } catch {
      alertMessage = "Failed to generate preview: \(error.localizedDescription)"
      showingAlert = true
    }
  }

  func printPreview(named name: String) async {
    guard let source = uiImage else { return }
    do {
      let adjusted = try processor.applyContrastBrightness(
        uiImage: source, contrast: contrast, brightness: brightness)
      guard let bin = try processor.binarizeForPrint(uiImage: adjusted, algorithm: name) else {
        alertMessage = "Unable to binarize image for \(name)"
        showingAlert = true
        return
      }
      let data = try printer.cmdsPrintImage(img: bin, energy: energyValue)
      try await printer.send(data: data)
      alertMessage = "Print job sent"
      showingAlert = true
    } catch {
      alertMessage = "Error: \(error.localizedDescription)"
      showingAlert = true
    }
  }

  func rotateLeft() {
    guard let source = uiImage else { return }
    uiImage = source.rotated(byDegrees: -90)
    Task { @MainActor in await generatePreview() }
  }

  func rotateRight() {
    guard let source = uiImage else { return }
    uiImage = source.rotated(byDegrees: 90)
    Task { @MainActor in await generatePreview() }
  }
}

// MARK: - Components

struct KawaiiGridItem: View {
    let title: String
    let icon: String // System Name
    let accentColor: Color
    let destination: WorkflowDestination
    
    var body: some View {
        NavigationLink(value: destination) {
            HStack {
                // Circular Icon Background
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                          .foregroundColor(accentColor)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                 RoundedRectangle(cornerRadius: 16)
                     .stroke(Color.gray.opacity(0.1), lineWidth: 1)
             )
        }
        .buttonStyle(.plain)
    }
}

// Custom Rounded Corner Shape
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Extensions (Unchanged)
extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil, from: nil, for: nil as UIEvent?)
  }
}

extension UIImage {
  func normalizedImage() -> UIImage {
    if self.imageOrientation == .up { return self }
    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    self.draw(in: CGRect(origin: .zero, size: self.size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(PrinterManager())
      .environmentObject(ModelManager())
  }
}
