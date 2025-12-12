import Foundation
import Combine
import ZIPFoundation // ⚠️ Add this package: https://github.com/weichsel/ZIPFoundation

class ModelDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var combinedProgress: Double = 0
    @Published var isDownloading = false
    @Published var statusMessage = ""
    @Published var error: String?

    // ⚠️ REPLACE THIS WITH YOUR HOSTED MODEL URL
    // Ensure the ZIP contains the 'compiled' folder at the root level.
    // Updated to user provided URL
    let modelZipURL = URL(string: "https://github.com/wolwire/CatPrinter-Ios-app/releases/download/1.0/compiled.zip")!

    private var cancellables = Set<AnyCancellable>()
    private var downloadTask: URLSessionDownloadTask?
    
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
        combinedProgress = 0

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session.downloadTask(with: modelZipURL)
        downloadTask?.resume()
    }

    private func unzip() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // ZIPFoundation adds .unzipItem to FileManager
                let progress = Progress()
                
                // Observe progress
                let observation = progress.observe(\.fractionCompleted) { p, _ in
                    DispatchQueue.main.async {
                        // Unzip phase is 50% -> 100% of total progress
                        self.combinedProgress = 0.5 + (p.fractionCompleted * 0.5)
                        self.statusMessage = "Unzipping: \(Int(p.fractionCompleted * 100))%"
                    }
                }
                
                try FileManager.default.unzipItem(at: self.zipFile, to: self.modelDirectory.deletingLastPathComponent(), progress: progress)
                
                observation.invalidate()
                
                DispatchQueue.main.async {
                    self.combinedProgress = 1.0
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
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let dlProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                // Download phase is 0% -> 50% of total progress
                self.combinedProgress = dlProgress * 0.5
                self.statusMessage = "Downloading: \(Int(dlProgress * 100))%"
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file immediately, before this method returns and the temp file is deleted!
        do {
            if FileManager.default.fileExists(atPath: self.zipFile.path) {
                try FileManager.default.removeItem(at: self.zipFile)
            }
            try FileManager.default.moveItem(at: location, to: self.zipFile)
            
            // Now notify UI and unzip
            DispatchQueue.main.async {
                self.combinedProgress = 0.5
                self.statusMessage = "Unzipping..."
                self.unzip()
            }
        } catch {
            let errorMsg = error.localizedDescription
            DispatchQueue.main.async {
                self.error = "File move error: \(errorMsg)"
                self.isDownloading = false
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isDownloading = false
            }
        }
    }
}
