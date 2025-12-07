import SwiftUI

struct BannerView: View {
    @State private var bannerText = "HELLO!"
    @State private var fontSize: Double = 60
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onSendToPrint: (UIImage) -> Void
    
    // Theme
    let themeColor = Color(red: 1.0, green: 0.8, blue: 0.6) // Pastel Orange
    
    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.98, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // PREVIEW CARD
                VStack {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // Simulated Banner Preview (Scrollable horizontal)
                    ScrollView(.horizontal) {
                        Text(bannerText.isEmpty ? " " : bannerText)
                            .font(.system(size: CGFloat(fontSize/2), weight: .black, design: .rounded)) // Scaled down for UI
                            .foregroundColor(.black)
                            .padding()
                            .overlay(
                                Rectangle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray.opacity(0.3))
                            )
                    }
                    .frame(height: 100)
                    .background(Color.white)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 2)
                
                // INPUT CARD
                VStack(spacing: 16) {
                    TextField("Enter text...", text: $bannerText)
                        .font(.headline)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .environment(\.colorScheme, .light)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("Size")
                            .foregroundColor(.black)
                        Slider(value: $fontSize, in: 20...150, step: 1)
                            .tint(themeColor)
                        Text("\(Int(fontSize))")
                            .foregroundColor(.black)
                            .monospacedDigit()
                    }
                }
                .padding()
                .background(Color.white)
                .environment(\.colorScheme, .light)
                .cornerRadius(20)
                .shadow(radius: 2)
                
                Spacer()
                
                Button {
                    let img = renderBanner()
                    onSendToPrint(img)
                } label: {
                    HStack {
                        Image(systemName: "printer.fill")
                        Text("Print Banner")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(28)
                    .shadow(radius: 5)
                }
                .disabled(bannerText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Banner Maker")
    }
    
    func renderBanner() -> UIImage {
        // Render text rotated 90 degrees or just long strip?
        // Usually thermal printers print vertically continuously.
        // We will generate a Long image with text rotated 90 degrees so it prints 'sideways' allowing long banners
        // OR just wide image if the printer driver handles it.
        // Assuming printer prints row by row (width 384).
        // To make a banner, we want the text to run ALONG the paper.
        // So we draw text normally, then ROTATE image -90 degrees.
        
        let font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: .black)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let textSize = (bannerText as NSString).size(withAttributes: attrs)
        
        // Add some padding
        let size = CGSize(width: textSize.width + 40, height: textSize.height + 40)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: size))
            (bannerText as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: attrs)
        }
        
        // Rotate 90 degrees so it prints long-ways
        // Actually, if we want it to print OUT of the printer as a banner:
        // The printer width is fixed (e.g. 384px). The height is variable.
        // If we want "HELLO" to come out long, we need the letters to be rotated -90 degrees relative to paper feed.
        // So 'H' top is facing 'Left' of paper.
        // So we take the wide image 'img' and rotate it -90 degrees.
        return img.rotated(byDegrees: -90)
    }
}
