import SwiftUI

struct CreateView: View {
    let themeColor: Color
    let onSendToPrint: (UIImage) -> Void

    @EnvironmentObject var modelManager: ModelManager
    @EnvironmentObject var apiService: ZImageAPIService

    // MARK: - User Inputs
    @State private var promptText = "A cute pastel cat, kawaii style"
    @State private var negativePrompt = ""
    @State private var guidanceScale: Double = 7.5
    @State private var seed: String = ""
    @State private var isNegativePromptExpanded = false

    @State private var generatedImage: UIImage?
    @State private var showZoomModal = false
    @State private var showSaveResult: Bool = false
    @State private var saveResultMessage: String = ""
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ------------------------
                    // API STATUS INDICATOR
                    // ------------------------
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(apiService.isConfigured ? .green : .orange)
                        Text(apiService.isConfigured ? "Cloud Generation" : "API Not Configured")
                            .font(.caption)
                            .foregroundColor(apiService.isConfigured ? .green : .orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                        
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
                            VStack(spacing: 12) {
                                ProgressView(value: modelManager.generationProgress, total: 1.0)
                                    .padding(.horizontal)
                                    .tint(.purple)

                                Text("Generating: \(Int(modelManager.generationProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.purple)

                                Button("Cancel") {
                                    modelManager.cancelGeneration()
                                }
                                .foregroundColor(.red)
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
                                Button {
                                    let saver = PhotoSaver()
                                    saver.writeToPhotoLibrary(img) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success:
                                                saveResultMessage = "Saved to Photos"
                                            case .failure(let err):
                                                saveResultMessage = "Save failed: \(err.localizedDescription)"
                                            }
                                            showSaveResult = true
                                        }
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
                .alert(saveResultMessage, isPresented: $showSaveResult) {
                    Button("OK", role: .cancel) { }
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
            stepCount: 9,
            guidanceScale: Float(guidanceScale),
            seed: numericSeed
        ) {
            await MainActor.run {
                self.generatedImage = img
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
