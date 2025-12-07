import SwiftUI
import Vision
import VisionKit

class OCRViewModel: NSObject, ObservableObject, VNDocumentCameraViewControllerDelegate {

    @MainActor @Published var scannedText: String = "Tap 'Scan Document' to begin."

    // MARK: - Create Scanner
    func makeScanner() -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        return scanner
    }

    // MARK: - Scan Completed
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true)

        Task {
            var text = ""

            for pageIndex in 0..<scan.pageCount {
                let img = scan.imageOfPage(at: pageIndex)
                text += await recognizeText(from: img) + "\n"
            }

            await MainActor.run {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.scannedText = cleaned.isEmpty ? "No text found." : cleaned
            }
        }
    }

    // MARK: - Scan Cancelled
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    // MARK: - Scan Failed
    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        print("Scanner error:", error.localizedDescription)
        controller.dismiss(animated: true)
    }

    // MARK: - OCR (async)
    func recognizeText(from image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }

        return await withCheckedContinuation { continuation in

            let request = VNRecognizeTextRequest { req, err in

                if let err = err {
                    print("OCR error:", err.localizedDescription)
                    continuation.resume(returning: "")
                    return
                }

                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let recognized = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: recognized)
            }

            request.recognitionLanguages = ["en-IN", "en-US"]
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                print("Vision handler error:", error.localizedDescription)
                continuation.resume(returning: "")
            }
        }
    }
}
