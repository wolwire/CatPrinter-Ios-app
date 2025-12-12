import SwiftUI

struct OCRView: View {
    @StateObject private var viewModel = OCRViewModel()
    @State private var showScanner = false
    @State private var previewImage: UIImage? = nil
    
    let onSendToPrint: (UIImage) -> Void
    
    // Theme
    let themeColor = Color(red: 0.6, green: 0.8, blue: 1.0) // Pastel Blue
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.backgroundLight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // CARD: Scanned Text
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .foregroundColor(themeColor)
                            Text("Extracted Text")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        Divider()
                        
                        ScrollView {
                            Text(viewModel.scannedText.isEmpty ? "Scan a document to see text here..." : viewModel.scannedText)
                                .font(.body)
                                .foregroundColor(viewModel.scannedText.isEmpty ? .gray : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: themeColor.opacity(0.1), radius: 5)
                    
                    // CARD: Preview
                    if let img = previewImage {
                        VStack(spacing: 12) {
                            Text("Print Preview")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            ZoomableImageView(image: img)
                                .frame(height: 250)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                    }
                    
                    // BUTTONS
                    HStack(spacing: 16) {
                        Button {
                            showScanner = true
                        } label: {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Scan")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: themeColor.opacity(0.4), radius: 6, y: 3)
                        }
                        
                        Button {
                            generatePreview()
                        } label: {
                            VStack {
                                Image(systemName: "doc.text.image")
                                    .font(.title2)
                                Text("Convert")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(themeColor)
                            .cornerRadius(16)
                            .shadow(radius: 2)
                        }
                    }
                    
                    if previewImage != nil {
                        Button {
                            if let img = previewImage { onSendToPrint(img) }
                        } label: {
                            Label("Send to Print", systemImage: "printer.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue) // Standard Blue for action
                                .cornerRadius(28)
                                .shadow(radius: 5)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("OCR")
            .background(AppDesignSystem.Colors.backgroundLight.ignoresSafeArea())
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView(viewModel: viewModel)
        }
    }
    
    // Logic (Same)
    func generatePreview() {
        previewImage = textToPrintImage(viewModel.scannedText)
    }
    
    func textToPrintImage(_ text: String, fontSize: CGFloat = 22) -> UIImage {
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let padding: CGFloat = 20
        let maxWidth: CGFloat = 384 - padding * 2
        
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let textRect = attributed.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let size = CGSize(width: maxWidth + padding * 2, height: textRect.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))
            attributed.draw(in: CGRect(x: padding, y: padding, width: maxWidth, height: textRect.height))
        }
    }
}
