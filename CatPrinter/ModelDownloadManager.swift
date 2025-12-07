import Foundation
import Combine
import ZIPFoundation // ⚠️ Add this package: https://github.com/weichsel/ZIPFoundation

class ModelDownloadManager: ObservableObject {
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var statusMessage = ""
    @Published var error: String?

    // ⚠️ REPLACE THIS WITH YOUR HOSTED MODEL URL
    // Ensure the ZIP contains the 'compiled' folder at the root level.
    // Updated to user provided URL
    let modelZipURL = URL(string: "https://github.com/wolwire/CatPrinter-Ios-app/releases/download/1.0/compiled.zip")!

    private var cancellables = Set<AnyCancellable>()

    // Path to 'compiled' folder
    var modelDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("compiled")
    }
    
    // Path to 'compiled.zip'
    var zipFile: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("compiled.zip")
    }

    func isModelDownloaded() -> Bool {
        return FileManager.default.fileExists(atPath: modelDirectory.path)
    }

    func startDownload() {
        guard !isDownloading else { return }
        isDownloading = true
        statusMessage = "Starting download..."
        error = nil
        downloadProgress = 0

        let task = URLSession.shared.downloadTask(with: modelZipURL) { localURL, response, err in
            DispatchQueue.main.async {
                if let err = err {
                    self.error = err.localizedDescription
                    self.isDownloading = false
                    return
                }

                guard let localURL = localURL else {
                    self.error = "Download failed."
                    self.isDownloading = false
                    return
                }

                self.statusMessage = "Unzipping..."
                // Move to Documents
                do {
                    if FileManager.default.fileExists(atPath: self.zipFile.path) {
                        try FileManager.default.removeItem(at: self.zipFile)
                    }
                    try FileManager.default.moveItem(at: localURL, to: self.zipFile)
                    self.unzip()
                } catch {
                    self.error = "File move error: \(error.localizedDescription)"
                    self.isDownloading = false
                }
            }
        }
        
        task.resume()
    }

    private func unzip() {
        do {
            // ZIPFoundation adds .unzipItem to FileManager
            try FileManager.default.unzipItem(at: zipFile, to: modelDirectory.deletingLastPathComponent())
            
            DispatchQueue.main.async {
                self.statusMessage = "Ready!"
                self.isDownloading = false
                try? FileManager.default.removeItem(at: self.zipFile)
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Unzip failed: \(error.localizedDescription). (Make sure ZIPFoundation package is added)"
                self.isDownloading = false
            }
        }
    }
}
