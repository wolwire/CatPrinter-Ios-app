import UIKit

/// Helper to save UIImage to Photos and capture completion via closure.
final class PhotoSaver: NSObject {
    private var completion: ((Result<Void, Error>) -> Void)?

    func writeToPhotoLibrary(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        // Normalize orientation before saving to ensure correct orientation in Photos
        let normalized = image.normalizedImage()
        UIImageWriteToSavedPhotosAlbum(normalized, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let err = error {
            completion?(.failure(err))
        } else {
            completion?(.success(()))
        }
        completion = nil
    }
}
