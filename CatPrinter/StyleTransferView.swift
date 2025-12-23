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
    
    @State private var guidance: Double = 0.55
    // Strength is a 0.0 - 1.0 value per zimage API
    @State private var strength: Double = 0.8
    @State private var seed: String = ""
    @State private var preserveColor: Bool = false
    @State private var showSaveResult: Bool = false
    @State private var saveResultMessage: String = ""
    
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
                        
                        // Guidance
                        HStack {
                            Text("Guidance").foregroundColor(themeColor)
                            Spacer()
                            Text(String(format: "%.1f", guidance))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $guidance, in: 0.0...10, step: 0.01)
                            .tint(themeColor)
                        
                        // Strength (0.0 - 1.0)
                        HStack {
                            Text("Style Strength").foregroundColor(themeColor)
                            Spacer()
                            Text(String(format: "%.2f", strength))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $strength, in: 0.0...1.0, step: 0.01)
                            .tint(themeColor)
                        Text("Higher = more style, Lower = preserve original")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // Preserve Color
                        Toggle(isOn: $preserveColor) {
                            Text("Preserve Colors")
                        }
                        .tint(themeColor)

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
                            VStack(spacing: 12) {
                                ProgressView(value: modelManager.generationProgress, total: 1.0)
                                    .padding(.horizontal)
                                    .tint(.purple)

                                Text("Transferring Style: \(Int(modelManager.generationProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.purple)

                                Button("Cancel") {
                                    modelManager.cancelGeneration()
                                }
                                .foregroundColor(.red)
                            }
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
                            
                            Button {
                                let saver = PhotoSaver()
                                saver.writeToPhotoLibrary(res) { result in
                                    switch result {
                                    case .success:
                                        saveResultMessage = "Saved to Photos"
                                    case .failure(let err):
                                        saveResultMessage = "Save failed: \(err.localizedDescription)"
                                    }
                                    showSaveResult = true
                                }
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                                    .font(.subheadline)
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
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
        .fullScreenCover(isPresented: $showZoomModal) {
            if let img = generatedImage {
                ZoomImageModal(image: img, isPresented: $showZoomModal)
            }
        }
        .alert(saveResultMessage, isPresented: $showSaveResult) {
            Button("OK", role: .cancel) { }
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
            if let result = await modelManager.generateStyleTransfer(
                prompt: fullPrompt,
                negativePrompt: fullNegative,
                originalImage: original,
                strength: Float(strength),
                stepCount: 9,
                seed: seedValue,
                preserveColor: preserveColor,
                cfg: Double(guidance)
            ) {
                await MainActor.run { self.generatedImage = result }
            }
        }
    }
}


// MARK: - Helpers
extension Color { static let transparent = Color.white.opacity(0) }
