import SwiftUI
import PhotosUI
import Vision

// MARK: - Style Template Model
struct StyleTemplate: Identifiable {
    let id = UUID()
    var name: String
    var promptModifier: String
    var negativePrompt: String
    let iconName: String
    let color: Color
}


// MARK: - Main View
struct StyleTransferView: View {
    let themeColor: Color
    let onSendToPrint: (UIImage) -> Void
    
    @EnvironmentObject var modelManager: ModelManager
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var showZoomModal = false
    
    @State private var selectedStyle: StyleTemplate?
    @State private var customPrompt: String = ""
    @State private var negativePrompt: String = "blurry, low quality, distorted, ugly"
    @State private var showNegativePrompt = false
    
    @State private var steps: Double = 35
    @State private var guidance: Double = 7.5
    @State private var strength: Double = 0.65
    @State private var seed: String = ""
    @State private var preserveFaces: Bool = true
    
    @State private var showingEditSheet = false
    @State private var editingStyle: StyleTemplate?
    
    @State private var styles = [
        StyleTemplate(name: "Sketch", promptModifier: "pencil sketch, hand-drawn, graphite texture, cross-hatching, monochromatic, expressive lines", negativePrompt: "color, painted, digital, smooth, photographic", iconName: "pencil.and.outline", color: .gray),
        StyleTemplate(name: "Anime", promptModifier: "anime style, studio ghibli, vibrant colors, cel shaded, clean outlines, expressive eyes, soft lighting, magical atmosphere", negativePrompt: "realistic, photographic, western cartoon, 3d render", iconName: "play.tv.fill", color: .indigo),
        StyleTemplate(name: "Oil Paint", promptModifier: "oil painting, van gogh style, thick impasto, bold brushstrokes, impressionist, rich colors, canvas texture", negativePrompt: "digital, smooth, clean lines, vector, flat", iconName: "paintpalette.fill", color: .orange),
        StyleTemplate(name: "Cyberpunk", promptModifier: "cyberpunk, neon lights, futuristic cityscape, holographic, rain-soaked streets, dystopian, purple and cyan, dramatic lighting", negativePrompt: "nature, vintage, pastoral, daylight, rural", iconName: "bolt.fill", color: .purple),
        StyleTemplate(name: "Vintage", promptModifier: "vintage photo, retro, sepia tone, grainy film, 1950s, polaroid, faded colors, nostalgic, soft vignette", negativePrompt: "modern, digital, sharp, high definition, vibrant", iconName: "camera.filters", color: .brown),
        StyleTemplate(name: "Origami", promptModifier: "origami paper art, geometric folds, angular shapes, crisp edges, 3d papercraft, minimalist, shadow depth", negativePrompt: "realistic, photographic, organic, smooth, painted", iconName: "doc.text.fill", color: .green),
        StyleTemplate(name: "Watercolor", promptModifier: "watercolor painting, soft colors, transparent washes, paper texture, paint bleeding, dreamy, light gradients", negativePrompt: "digital, sharp edges, solid colors, photographic", iconName: "paintbrush", color: .blue),
        StyleTemplate(name: "Comic", promptModifier: "comic book art, bold outlines, action lines, halftone dots, pop art, flat colors, dramatic shadows, retro", negativePrompt: "realistic, photographic, blurry, soft, 3d render", iconName: "book.fill", color: .red)
    ]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    
    // MARK: - BODY
    var body: some View {
        ZStack {
AppDesignSystem.Colors.backgroundLight
            .ignoresSafeArea()
        
        if modelManager.modelMissing {
            ModelDownloadView {
                modelManager.retryLoad()
            }
        } else {
            ScrollView {
                
                // MARK: - IMAGE PICKER
                if let img = selectedImage {
                    HStack(spacing: 12) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.gray)
                        
                        if let res = generatedImage {
                            Image(uiImage: res)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
                                .onTapGesture { showZoomModal = true }
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(Text("?").font(.largeTitle))
                        }
                    }
                    .padding()

                    // Preserve Faces Toggle
                    Toggle(isOn: $preserveFaces) {
                        Label("Preserve faces (auto mask)", systemImage: "face.smiling")
                    }
                    .tint(themeColor)
                    .padding(.horizontal)
                    
                    Button("Change Image") {
                        selectedItem = nil
                        selectedImage = nil
                        generatedImage = nil
                    }
                    .buttonStyle(.bordered)
                    
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                            Text("Select an Image")
                                .font(.headline)
                        }
                        .foregroundColor(themeColor)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(themeColor.opacity(0.1))
                        .cornerRadius(20)
                        .padding()
                    }
                }
                
                
                // MARK: - STYLE GRID
                if selectedImage != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose a Style")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(styles) { style in
                                Button {
                                    withAnimation { 
                                        selectedStyle = style
                                        customPrompt = style.promptModifier
                                        negativePrompt = style.negativePrompt
                                    }
                                } label: {
                                    VStack {
                                        Image(systemName: style.iconName)
                                            .font(.system(size: 30))
                                            .foregroundColor(selectedStyle?.id == style.id ? .white : style.color)
                                        
                                        Text(style.name)
                                            .font(.caption)
                                            .foregroundColor(selectedStyle?.id == style.id ? .white : .black.opacity(0.7))
                                    }
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedStyle?.id == style.id ? style.color : Color.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                
                
                // MARK: - PROMPTS + SETTINGS + GENERATE
                if selectedImage != nil {
                    
                    VStack(spacing: 20) {
                        
                        // Positive Prompt (Single Field)
                        AppSectionHeader("Style Prompt", color: themeColor)
                        AppTextEditor(text: $customPrompt, height: 80)
                        // Toggle negative prompt
                        Button {
                            withAnimation { showNegativePrompt.toggle() }
                        } label: {
                            HStack {
                                Text("Negative Prompts (Optional)")
                                Spacer()
                                Image(systemName: showNegativePrompt ? "chevron.down" : "chevron.right")
                            }
                            .foregroundColor(.gray)
                        }
                        
                        if showNegativePrompt {
                            AppTextEditor(text: $negativePrompt, height: 80)
                        }
                        
                        
                        // Settings
                        Text("Settings").font(.subheadline).bold().foregroundColor(.gray)
                        
                        // Steps
                        HStack {
                            Text("Steps")
                            .foregroundColor(themeColor)
                            Spacer()
                            Text("\(Int(steps))")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $steps, in: 10...50, step: 1)
                            .tint(themeColor)
                        
                        // Guidance
                        HStack {
                            Text("Guidance").foregroundColor(themeColor)
                            Spacer()
                            Text(String(format: "%.1f", guidance))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $guidance, in: 1...15, step: 0.5)
                            .tint(themeColor)
                        
                        // Strength
                        HStack {
                            Text("Style Strength").foregroundColor(themeColor)
                            Spacer()
                            Text(String(format: "%.2f", strength))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $strength, in: 0.3...0.9, step: 0.05)
                            .tint(themeColor)
                        Text("Higher = more style, Lower = preserve original")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // Seed
                        HStack {
                            Text("Seed (Random if empty)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            TextField("Random", text: $seed)
                                .keyboardType(.numberPad)
                                .frame(width: 90)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(themeColor)
                        }
                        
                        
                        // GENERATE BUTTON
                        if modelManager.isGenerating {
                            ProgressView("Transferring Style...", value: modelManager.generationProgress, total: 1.0)
                                .padding()
                        } else {
                            Button {
                                runStyleTransfer()
                            } label: {
                                Text("Generate Magic")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(selectedStyle == nil ? Color.gray : themeColor)
                                    .cornerRadius(16)
                            }
                            .disabled(selectedStyle == nil)
                        }
                        
                        
                        // SEND TO PRINT
                        if let res = generatedImage {
                            Button {
                                onSendToPrint(res)
                            } label: {
                                Label("Send to Print", systemImage: "printer.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 6)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Style Transfer")
            .background(AppDesignSystem.Colors.backgroundLight.ignoresSafeArea())
            .onChange(of: selectedItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run {
                            self.selectedImage = img
                            self.generatedImage = nil
                        }
                    }
                }
            }
            
        }
        }
        .fullScreenCover(isPresented: $showZoomModal) {
            if let img = generatedImage {
                ZoomImageModal(image: img, isPresented: $showZoomModal)
            }
        }
    }
    
    
    // MARK: - GENERATE LOGIC
    func runStyleTransfer() {
        guard let original = selectedImage, let style = selectedStyle else { return }
        
        // Use prompt as-is (user can edit from style template)
        let fullPrompt: String
        if customPrompt.isEmpty {
            // Fallback to style default if user cleared the field
            fullPrompt = style.promptModifier
        } else {
            // Use user's prompt (which may be edited from style template)
            fullPrompt = customPrompt
        }
        
        // Use negative prompt as-is
        let fullNegative = negativePrompt
        
        let seedValue: UInt32 = UInt32(seed) ?? UInt32.random(in: 0...50000)
        
        print("🎨 Style Transfer Prompt: \(fullPrompt)")
        print("🚫 Negative Prompt: \(fullNegative)")
        print("💪 Strength: \(strength)")
        
        Task {
            if preserveFaces {
                // Build an inpainting mask that PROTECTS the face: black on face, white elsewhere
                let boxes = detectFaceBoxes(in: original)
                let mask = buildPreserveFaceMask(originalSize: original.size, boxes: boxes)
                if let result = await modelManager.generateInpaint(
                    prompt: fullPrompt,
                    negativePrompt: fullNegative,
                    originalImage: original,
                    maskImage: mask,
                    stepCount: Int(steps),
                    guidanceScale: Float(guidance),
                    seed: seedValue
                ) {
                    await MainActor.run { self.generatedImage = result }
                }
            } else {
                if let result = await modelManager.generateStyleTransfer(
                    prompt: fullPrompt,
                    negativePrompt: fullNegative,
                    originalImage: original,
                    strength: Float(strength),
                    stepCount: Int(steps),
                    guidanceScale: Float(guidance),
                    seed: seedValue
                ) {
                    await MainActor.run { self.generatedImage = result }
                }
            }
        }
    }

    // MARK: - Face Detection & Compositing
    private func preserveFacesByCompositingFace(original: UIImage, stylized: UIImage) -> UIImage {
        guard let cgOrig = original.cgImage, let cgStylized = stylized.cgImage else { return stylized }
        let size = CGSize(width: cgStylized.width, height: cgStylized.height)

        // Detect faces on the original image
        let faceBoxes = detectFaceBoxes(in: original)
        if faceBoxes.isEmpty { return stylized }

        // Prepare context
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: stylized.size.width, height: stylized.size.height))
        return renderer.image { ctx in
            // Draw stylized image first
            UIImage(cgImage: cgStylized, scale: stylized.scale, orientation: stylized.imageOrientation)
                .draw(in: CGRect(origin: .zero, size: stylized.size))

            // Composite original face regions on top
            for box in faceBoxes {
                // Convert normalized Vision bbox to pixel coordinates of stylized image
                let rect = convertVisionRect(box, from: original.size, to: stylized.size)
                // Crop original image to rect
                if let cropped = crop(image: original, to: rect) {
                    cropped.draw(in: rect)
                }
            }
        }
    }

    private func detectFaceBoxes(in image: UIImage) -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNFaceObservation] ?? []
            return observations.map { $0.boundingBox } // normalized coordinates
        } catch {
            return []
        }
    }

    // Build a mask that protects faces (black face regions, white elsewhere)
    private func buildPreserveFaceMask(originalSize: CGSize, boxes: [CGRect]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: originalSize)
        return renderer.image { _ in
            // Start with WHITE everywhere: areas to be stylized
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: originalSize)).fill()

            // Paint BLACK over each face box to protect it from stylization
            UIColor.black.setFill()
            for box in boxes {
                let rect = convertVisionRect(box, from: originalSize, to: originalSize)
                // Slightly expand rect to include hairline/beard margin
                let expanded = rect.insetBy(dx: -rect.width * 0.08, dy: -rect.height * 0.08)
                UIBezierPath(roundedRect: expanded, cornerRadius: min(expanded.width, expanded.height) * 0.15).fill()
            }
        }
    }

    private func convertVisionRect(_ rect: CGRect, from srcSize: CGSize, to dstSize: CGSize) -> CGRect {
        // VN boundingBox is normalized with origin at bottom-left; UIKit has origin at top-left
        let x = rect.origin.x * dstSize.width
        let y = (1 - rect.origin.y - rect.size.height) * dstSize.height
        let w = rect.size.width * dstSize.width
        let h = rect.size.height * dstSize.height
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func crop(image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let scaleX = CGFloat(cg.width) / image.size.width
        let scaleY = CGFloat(cg.height) / image.size.height
        let scaledRect = CGRect(x: rect.origin.x * scaleX,
                                y: rect.origin.y * scaleY,
                                width: rect.size.width * scaleX,
                                height: rect.size.height * scaleY)
        guard let cropped = cg.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}


// MARK: - Helpers
extension Color { static let transparent = Color.white.opacity(0) }
