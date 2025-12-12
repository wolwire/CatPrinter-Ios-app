import SwiftUI
import PhotosUI
import PencilKit

struct InpaintingView: View {
    let themeColor: Color
    let onSendToPrint: (UIImage) -> Void
    
    @EnvironmentObject var modelManager: ModelManager
    @State private var canvasView = PKCanvasView()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var prompt: String = ""
    @State private var generatedImage: UIImage?
    @State private var showZoomModal = false
    @State private var negativePrompt: String = "blurry, low quality, distorted"
    @State private var showNegativePrompt: Bool = false
    @State private var steps: Double = 35
    @State private var guidance: Double = 7.5
    @State private var seed: String = ""
    
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
            .ignoresSafeArea()
        
        if modelManager.modelMissing {
            ModelDownloadView {
                modelManager.retryLoad()
            }
        }
        else {
            ScrollView {
                VStack(spacing: 20) {
                    // --- 1. Image Picker ---
                    if let img = selectedImage {
                        HStack(spacing: 12) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(themeColor)
                            
                            if let res = generatedImage {
                                Image(uiImage: res)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeColor, lineWidth: 2)
                                    )
                                    .onTapGesture { showZoomModal = true }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .overlay(Text("?").font(.largeTitle).foregroundColor(themeColor))
                            }
                        }
                        
                        Button("Change Image") {
                            selectedItem = nil
                            selectedImage = nil
                            generatedImage = nil
                            canvasView.drawing = PKDrawing()
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(themeColor.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    
                    // --- 2. Canvas Over Image ---
                    if selectedImage != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Draw Mask")
                                .font(.caption)
                                .bold()
                                .foregroundColor(KawaiiTheme.textDark)
                            
                            Text("Draw over the areas you want to change")
                                .font(.caption)
                                .foregroundColor(KawaiiTheme.textDark)
                            
                            ZStack {
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 300)
                                        .cornerRadius(12)
                                }
                                
                                CanvasView(canvasView: $canvasView, selectedImage: selectedImage)
                                    .frame(height: 300)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeColor.opacity(0.3), lineWidth: 2)
                                    )
                            }
                            
                            HStack {
                                Button {
                                    canvasView.drawing = PKDrawing()
                                } label: {
                                    Label("Clear Mask", systemImage: "trash")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                                Text("Use red pen to draw")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 6)
                    }
                    
                    // --- 3. Prompt Section ---
                    if selectedImage != nil {
                        AppCardWithPadding {
                            VStack(alignment: .leading, spacing: 12) {
                                
                                AppSectionHeader("Describe your idea", color: themeColor)
                                AppTextEditor(text: $prompt, height: 100)
                                
                                // Negative Prompt
                                Button {
                                    withAnimation { showNegativePrompt.toggle() }
                                } label: {
                                    HStack {
                                        Text("Negative Prompt (Optional)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: showNegativePrompt ? "chevron.down" : "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                if showNegativePrompt {
                                    TextEditor(text: $negativePrompt)
                                        .frame(height: 80)
                                        .padding(8)
                                        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                        .cornerRadius(12)
                                        .transition(.opacity)
                                }
                                
                                // Settings
                                Text("Settings")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                
                                VStack(spacing: 16) {
                                    // Steps
                                    HStack {
                                        Text("Steps")
                                        Spacer()
                                        Text("\(Int(steps))")
                                    }
                                    Slider(value: $steps, in: 10...50, step: 1)
                                    
                                    // Guidance
                                    HStack {
                                        Text("Guidance")
                                        Spacer()
                                        Text(String(format: "%.1f", guidance))
                                    }
                                    Slider(value: $guidance, in: 1...15, step: 0.5)
                                    
                                    // Seed
                                    HStack {
                                        Text("Seed (Optional)")
                                            .font(.caption)
                                        Spacer()
                                        TextField("Random", text: $seed)
                                            .keyboardType(.numberPad)
                                            .frame(width: 100)
                                            .padding(8)
                                            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            // Generate Button
                            if modelManager.isGenerating {
                                ProgressView("Generating Magic...", value: modelManager.generationProgress, total: 1)
                                    .padding()
                            } else {
                                Button {
                                    runInpainting()
                                } label: {
                                    Text("Generate Magic")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(prompt.isEmpty ? Color.gray : themeColor)
                                        .cornerRadius(16)
                                }
                                .disabled(prompt.isEmpty)
                                .padding(.top)
                            }
                            
                            // Print Button
                            if let res = generatedImage {
                                Button {
                                    onSendToPrint(res)
                                } label: {
                                    Label("Send to Print", systemImage: "printer.fill")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            
            .navigationTitle("Magic Edit")
            .background(AppDesignSystem.Colors.backgroundLight.ignoresSafeArea())
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            generatedImage = nil
                            canvasView.drawing = PKDrawing()
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
    
    // --- Inpainting Logic ---
    func runInpainting() {
        guard let original = selectedImage else { return }
        
        let maskImage = extractMask(from: canvasView, size: original.size)
        let seedValue = UInt32(seed) ?? UInt32.random(in: 0...50000)
        
        Task {
            if let result = await modelManager.generateInpaint(
                prompt: prompt,
                negativePrompt: negativePrompt,
                originalImage: original,
                maskImage: maskImage,
                stepCount: Int(steps),
                guidanceScale: Float(guidance),
                seed: seedValue
            ) {
                await MainActor.run {
                    generatedImage = result
                }
            }
        }
    }
    
    func extractMask(from canvas: PKCanvasView, size: CGSize) -> UIImage {
        let drawingImage = canvas.drawing.image(from: canvas.bounds, scale: 1)
        let templateImage = drawingImage.withRenderingMode(.alwaysTemplate)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.black.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            
            UIColor.white.setFill()
            templateImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// --- CanvasView Wrapper ---
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let selectedImage: UIImage?
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        let ink = PKInkingTool(.pen, color: .red, width: 20)
        canvasView.tool = ink
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

extension UIImage {
    func contrastInverted() -> UIImage? { self }
}
