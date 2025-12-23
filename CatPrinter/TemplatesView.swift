import SwiftUI
import PhotosUI

struct Template: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let color: Color
}

struct TemplatesView: View {
    let onSendToPrint: (UIImage) -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var currentTemplate: Template?
    @State private var isRendering = false
    
    // Sample Templates mimicking the user's screenshot where possible
    let templates = [
        Template(name: "Stamp", systemImage: "envelope", color: .purple),
        Template(name: "Circle", systemImage: "circle", color: .blue),
        Template(name: "Bunny", systemImage: "hare", color: .pink),
        Template(name: "Bulb", systemImage: "lightbulb", color: .yellow),
        Template(name: "Puzzle", systemImage: "puzzlepiece", color: .green),
        Template(name: "Bubble", systemImage: "bubble.left", color: .orange)
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                
                if let template = currentTemplate, let img = selectedImage {
                    // EDITOR MODE
                    VStack {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Composition View
                        ZStack {
                            Color.white
                            
                            // User Image
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 300)
                                .clipShape(Rectangle())
                                .mask(
                                    // Simple masking based on template type
                                    getMask(for: template)
                                        .frame(width: 280, height: 280)
                                )
                            
                            // Frame Overlay (Stroke)
                            getFrame(for: template)
                                .stroke(Color.black, lineWidth: 8)
                                .frame(width: 300, height: 300)
                        }
                        .frame(width: 320, height: 320)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .id(UUID()) // Force redraw if needed
                        
                        HStack(spacing: 16) {
                            Button("Change Photo") {
                                selectedItem = nil
                                selectedImage = nil
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button {
                                renderAndPrint(template: template, image: img)
                            } label: {
                                Label("Print", systemImage: "printer.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding()
                        
                        Button("Choose Different Template") {
                            withAnimation {
                                currentTemplate = nil
                                selectedImage = nil
                                selectedItem = nil
                            }
                        }
                        .padding(.top, 8)
                    }
                    .transition(.move(edge: .bottom))
                    
                } else {
                    // GRID MODE
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            Button {
                                currentTemplate = template
                            } label: {
                                VStack {
                                    Image(systemName: template.systemImage)
                                        .font(.system(size: 60))
                                        .foregroundColor(template.color)
                                        .frame(height: 100)
                                    
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedImage == nil ? Color.clear : Color.blue, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            }
        }
        .background(AppDesignSystem.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Templates")
        // Photo Picker Binding
        .photosPicker(isPresented: Binding(
            get: { currentTemplate != nil && selectedImage == nil },
            set: { if !$0 { /* handle dismissal if needed */ } }
        ), selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation {
                            self.selectedImage = image
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func getMask(for template: Template) -> some View {
        switch template.name {
        case "Circle": return AnyView(Circle())
        case "Bunny": return AnyView(BunnyShape())
        case "Bulb": return AnyView(BulbShape())
        case "Puzzle": return AnyView(PuzzleShape())
        case "Bubble": return AnyView(BubbleShape())
        case "Stamp": return AnyView(StampShape())
        default: return AnyView(Rectangle())
        }
    }
    
    // Return AnyShape directly without @ViewBuilder
    func getFrame(for template: Template) -> AnyShape {
        switch template.name {
        case "Circle": return AnyShape(Circle())
        case "Bunny": return AnyShape(BunnyShape())
        case "Bulb": return AnyShape(BulbShape())
        case "Puzzle": return AnyShape(PuzzleShape())
        case "Bubble": return AnyShape(BubbleShape())
        case "Stamp": return AnyShape(StampShape())
        default: return AnyShape(Rectangle())
        }
    }
    
    @MainActor
    func renderAndPrint(template: Template, image: UIImage) {
        let renderer = ImageRenderer(content:
            ZStack {
                Color.white
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 500, height: 500)
                    .mask(getMask(for: template).frame(width: 480, height: 480))
                
                getFrame(for: template)
                    .stroke(Color.black, lineWidth: 15)
                    .frame(width: 500, height: 500)
            }
            .frame(width: 500, height: 500)
        )
        
        if let result = renderer.uiImage {
            onSendToPrint(result)
        }
    }
}

// Type eraser for Shapes
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ wrapped: S) {
        _path = { rect in
            let path = wrapped.path(in: rect)
            return path
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Custom Shapes

struct StampShape: Shape {
    func path(in rect: CGRect) -> Path {
        // A approximation of a stamp with wavy edges
        var path = Path()
        let waveCount = 10
        let waveHeight: CGFloat = 5
        
        let dx = rect.width / CGFloat(waveCount)
        let dy = rect.height / CGFloat(waveCount)
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge
        for i in 0..<waveCount {
            let x = CGFloat(i) * dx
            path.addQuadCurve(to: CGPoint(x: x + dx, y: 0), control: CGPoint(x: x + dx/2, y: waveHeight))
        }
        
        // Right edge
        for i in 0..<waveCount {
            let y = CGFloat(i) * dy
            path.addQuadCurve(to: CGPoint(x: rect.width, y: y + dy), control: CGPoint(x: rect.width - waveHeight, y: y + dy/2))
        }
        
        // Bottom edge
        for i in 0..<waveCount {
            let x = rect.width - CGFloat(i) * dx
            path.addQuadCurve(to: CGPoint(x: x - dx, y: rect.height), control: CGPoint(x: x - dx/2, y: rect.height - waveHeight))
        }
        
        // Left edge
        for i in 0..<waveCount {
            let y = rect.height - CGFloat(i) * dy
            path.addQuadCurve(to: CGPoint(x: 0, y: y - dy), control: CGPoint(x: waveHeight, y: y - dy/2))
        }
        
        path.closeSubpath()
        return path
    }
}

struct BunnyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Main body (circle-ish)
        let bodyRect = CGRect(x: rect.width * 0.1, y: rect.height * 0.3, width: rect.width * 0.8, height: rect.height * 0.65)
        path.addEllipse(in: bodyRect)
        
        // Ears
        let earWidth = rect.width * 0.15
        let earHeight = rect.height * 0.35
        let leftEar = CGRect(x: rect.width * 0.25, y: 0, width: earWidth, height: earHeight)
        let rightEar = CGRect(x: rect.width * 0.60, y: 0, width: earWidth, height: earHeight)
        
        path.addEllipse(in: leftEar)
        path.addEllipse(in: rightEar)
        
        return path
    }
}

struct BulbShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Bulb sphere on top
        let bulbRect = CGRect(x: rect.width * 0.15, y: rect.height * 0.05, width: rect.width * 0.7, height: rect.width * 0.7)
        path.addEllipse(in: bulbRect)
        
        // Base
        let baseX = rect.width * 0.35
        let baseY = rect.height * 0.65
        let baseW = rect.width * 0.3
        let baseH = rect.height * 0.2
        path.addRect(CGRect(x: baseX, y: baseY, width: baseW, height: baseH))
        
        // Screw thread (simplified)
        path.addRect(CGRect(x: baseX + 5, y: baseY + baseH, width: baseW - 10, height: baseH * 0.5))
        
        return path
    }
}

struct PuzzleShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Simplified puzzle piece: a square with an circular tab on right and bottom, and cutouts on top and left
        // Actually, let's do a classic "all tabs out" or consistent shape.
        // Let's do: Top (In), Right (Out), Bottom (In), Left (Out)
        
        let width = rect.width
        let height = rect.height
        let tabSize = width * 0.2
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top Edge (with cutout)
        path.addLine(to: CGPoint(x: width * 0.4, y: 0))
        path.addArc(center: CGPoint(x: width * 0.5, y: 0), radius: tabSize/2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false) // concave
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // Right Edge (with tab)
        path.addLine(to: CGPoint(x: width, y: height * 0.4))
        path.addArc(center: CGPoint(x: width, y: height * 0.5), radius: tabSize/2, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false) // convex
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Bottom Edge (with cutout)
        path.addLine(to: CGPoint(x: width * 0.6, y: height))
        path.addArc(center: CGPoint(x: width * 0.5, y: height), radius: tabSize/2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false) // concave
        path.addLine(to: CGPoint(x: 0, y: height))
        
        // Left Edge (with tab)
        path.addLine(to: CGPoint(x: 0, y: height * 0.6))
        path.addArc(center: CGPoint(x: 0, y: height * 0.5), radius: tabSize/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false) // convex
        path.closeSubpath()
        return path
    }
}

struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Main bubble
        let bubbleRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height * 0.8)
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: 30, height: 30))
        
        // Tail
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.width * 0.1, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.8))
        
        return path
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.black)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
