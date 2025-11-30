import SwiftUI

struct CreateView: View {
    let themeColor: Color

    // 1. ModelManager must conform to ObservableObject for @StateObject to work.
    @StateObject private var modelManager = ModelManager()
    @State private var promptText: String = "A cute pastel cat, kawaii style"
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                promptHeader

                promptEditor

                generateButton

                Divider()

                generatedImageSection

                Spacer()
            }
            .padding()
            .navigationTitle("Create")
        }
    }

    // MARK: UI Components

    private var promptHeader: some View {
        Text("Prompt")
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var promptEditor: some View {
        TextEditor(text: $promptText)
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2))
            )
    }

    private var generateButton: some View {
        Button(action: { Task { await generate() } }) {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                }
                Text(isGenerating ? "Generating…" : "Generate")
                    .bold()
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(themeColor)
        .disabled(isGenerating)
    }

    private var generatedImageSection: some View {
        Group {
            if let img = generatedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .padding(.top, 8)
            } else if isGenerating {
                // Placeholder/Loading state for the image display area
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    Text("Generating image… this may take a moment.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, idealHeight: 250)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .transition(.opacity)
            } else {
                // Initial state
                VStack(spacing: 8) {
                    Text("No image yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Enter a prompt and tap Generate to create an image.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, idealHeight: 250)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: Generator Call

    private func generate() async {
        guard !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await MainActor.run {
            isGenerating = true
            generatedImage = nil
        }

        let img = await modelManager.generate(prompt: promptText)

        await MainActor.run {
            generatedImage = img
            isGenerating = false
        }
        modelManager.clearCache()   
    }
}

struct CreateView_Previews: PreviewProvider {
    static var previews: some View {
        CreateView(themeColor: .pink)
    }
}
