import SwiftUI

struct CreateView: View {
    let themeColor: Color
    let onSendToPrint: (UIImage) -> Void

    @EnvironmentObject var modelManager: ModelManager

    // MARK: - User Inputs
    @State private var promptText = "A cute pastel cat, kawaii style"
    @State private var negativePrompt = ""
    @State private var stepCount: Double = 35
    @State private var guidanceScale: Double = 7.5
    @State private var seed: String = ""
    @State private var isNegativePromptExpanded = false

    @State private var generatedImage: UIImage?
    @State private var showZoomModal = false
    
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
                    VStack(spacing: 20) {
                        
                        // ------------------------
                        // PROMPT CARD
                        // ------------------------
                        VStack(alignment: .leading, spacing: 12) {
                            AppSectionHeader("Describe your idea",
                                             color: AppDesignSystem.Colors.pastelPurple)
                            
                            AppTextEditor(text: $promptText, height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppDesignSystem.Colors.pastelPurple, lineWidth: 1))
                                .shadow(color: AppDesignSystem.Colors.pastelPurple.opacity(0.1),
                                        radius: 4)
                            
                            DisclosureGroup(isExpanded: $isNegativePromptExpanded) {
                                AppTextEditor(text: $negativePrompt, height: 80)
                            } label: {
                                Text("Negative Prompt (Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tint(AppDesignSystem.Colors.pastelPurple)
                        }
                        .padding()
                        .background(Color.white)
                        .environment(\.colorScheme, .light)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
                        
                        // ------------------------
                        // CONFIG CARD
                        // ------------------------
                        VStack(alignment: .leading, spacing: 16) {
                            AppSettingsHeader("Settings")
                            
                            VStack(spacing: AppDesignSystem.Spacing.lg) {
                                
                                AppSettingsSlider(
                                    value: $stepCount,
                                    in: 10...70,
                                    step: 1,
                                    label: "Steps",
                                    color: AppDesignSystem.Colors.pastelPurple,
                                    valueFormatter: { "\(Int($0))" }
                                )
                                
                                AppSettingsSlider(
                                    value: $guidanceScale,
                                    in: 1...20,
                                    step: 0.1,
                                    label: "Guidance",
                                    color: AppDesignSystem.Colors.pastelPurple
                                )
                                
                                AppConfigTextField("Seed (Random if empty)",
                                                   text: $seed)
                                    .keyboardType(.numberPad)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .environment(\.colorScheme, .light)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
                        
                        // ------------------------
                        // GENERATION PROGRESS
                        // ------------------------
                        if modelManager.isGenerating {
                            VStack {
                                ProgressView(value: modelManager.generationProgress, total: 1.0)
                                    .padding(.horizontal)
                                    .tint(.purple)
                                
                                Text("Generating: \(Int(modelManager.generationProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        
                        // ------------------------
                        // ACTION BUTTON
                        // ------------------------
                        Button {
                            Task { await generate() }
                        } label: {
                            Text(modelManager.isGenerating ? "Painting..." : "Generate Magic")
                                .font(.headline)
                                .foregroundColor(AppDesignSystem.Colors.textBlack.opacity(0.8))
                                .frame(maxWidth: .infinity, minHeight: 55)
                                .background(AppDesignSystem.Colors.pastelPurple)
                                .cornerRadius(27.5)
                                .shadow(color: AppDesignSystem.Colors.pastelPurple.opacity(0.5),
                                        radius: 8, y: 4)
                        }
                        .disabled(modelManager.isGenerating)
                        
                        if modelManager.isGenerating {
                            Button("Cancel") { modelManager.cancelGeneration() }
                                .foregroundColor(.red)
                        }
                        
                        
                        // ------------------------
                        // RESULT IMAGE (FIXED!)
                        // ------------------------
                        if let img = generatedImage {
                            VStack(spacing: 16) {
                                
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                    .shadow(radius: 5)
                                    .onTapGesture { showZoomModal = true }
                                        .fullScreenCover(isPresented: $showZoomModal) {
                                            if let img = generatedImage {
                                                ZoomImageModal(image: img, isPresented: $showZoomModal)
                                            }
                                        }
                                
                                Button {
                                    onSendToPrint(img)
                                } label: {
                                    Label("Send to Print", systemImage: "printer.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green.opacity(0.7))
                                        .cornerRadius(16)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
                .onTapGesture { hideKeyboard() }
            }
        }
    }
    
    
    // MARK: - Generation Logic
    private func generate() async {
        guard !promptText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        generatedImage = nil
        
        let numericSeed: UInt32 = UInt32(seed) ?? UInt32.random(in: 1...UInt32.max)
        
        if let img = await modelManager.generate(
            prompt: promptText,
            negativePrompt: negativePrompt,
            stepCount: Int(stepCount),
            guidanceScale: Float(guidanceScale),
            seed: numericSeed
        ) {
            await MainActor.run {
                self.generatedImage = img
            }
        }
    }
}
