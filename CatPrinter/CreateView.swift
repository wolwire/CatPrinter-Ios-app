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
    
    // Theme
    let pastelPurple = Color(red: 0.8, green: 0.7, blue: 1.0)
    let paperColor = Color(red: 0.99, green: 0.99, blue: 1.0)

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 1.0) // Very light purple
                .ignoresSafeArea()
            
            if modelManager.modelMissing {
                ModelDownloadView {
                    modelManager.retryLoad()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // PROMPT CARD
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Describe your idea")
                                .font(.headline)
                                .foregroundColor(.purple.opacity(0.8))
                            
                            TextEditor(text: $promptText)
                                .scrollContentBackground(.hidden)
                                .padding()
                                .background(paperColor)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(pastelPurple, lineWidth: 1))
                                .frame(height: 100)
                                .shadow(color: pastelPurple.opacity(0.1), radius: 4)
                            
                            DisclosureGroup(isExpanded: $isNegativePromptExpanded) {
                                TextEditor(text: $negativePrompt)
                                    .scrollContentBackground(.hidden)
                                    .padding()
                                    .background(paperColor)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                    .frame(height: 80)
                            } label: {
                                Text("Negative Prompt (Optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tint(.purple)
                        }
                        .padding()
                        .background(Color.white)
                        .environment(\.colorScheme, .light) // Force dark text
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
                        // CONFIG CARD
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("Steps")
                                    .foregroundColor(.black)
                                Spacer()
                                Text("\(Int(stepCount))").bold().foregroundColor(.purple)
                            }
                            Slider(value: $stepCount, in: 10...70, step: 1).tint(pastelPurple)
                            
                            HStack {
                                Text("Guidance")
                                    .foregroundColor(.black)
                                Spacer()
                                Text(String(format: "%.1f", guidanceScale)).bold().foregroundColor(.purple)
                            }
                            Slider(value: $guidanceScale, in: 1...20, step: 0.1).tint(pastelPurple)
                            
                            TextField("Seed (Random if empty)", text: $seed)
                                .keyboardType(.numberPad)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.white)
                        .environment(\.colorScheme, .light) // Force dark text
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        
                        // ACTION
                        Button {
                            Task { await generate() }
                        } label: {
                            HStack {
                                if modelManager.isGenerating { ProgressView().tint(.white) }
                                Text(modelManager.isGenerating ? "Painting..." : "Generate Magic")
                            }
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(pastelPurple)
                            .cornerRadius(27.5)
                            .shadow(color: pastelPurple.opacity(0.5), radius: 8, y: 4)
                        }
                        .disabled(modelManager.isGenerating)
                        
                        if modelManager.isGenerating {
                            Button("Cancel") { modelManager.cancelGeneration() }
                                .foregroundColor(.red)
                        }
                        
                        // RESULT
                        if let img = generatedImage {
                            VStack(spacing: 16) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                    .shadow(radius: 5)
                                
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
    
    // Logic (Identical to before)
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
            await MainActor.run { self.generatedImage = img }
        }
    }
}

struct ModelDownloadView: View {
    @StateObject private var downloadManager = ModelDownloadManager()
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("AI Models Missing")
                .font(.title2)
                .bold()
                .foregroundColor(.black)
            
            Text("To use AI features, you need to download the model pack (~2GB). This only needs to be done once.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if downloadManager.isDownloading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text(downloadManager.statusMessage)
                        .foregroundColor(.purple)
                        .font(.caption)
                }
            } else {
                Button {
                    downloadManager.startDownload()
                } label: {
                    Text("Download Models")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(16)
                }
            }
            
            if let error = downloadManager.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Check for completion
            if downloadManager.statusMessage == "Ready!" {
                Button {
                    onComplete()
                } label: {
                    Text("Start Creating!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(16)
                }
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding()
    }
}
