import Foundation
import UIKit
import SwiftUI

class ModelManager: ObservableObject {

    // UI state — must be marked @MainActor
    @MainActor @Published var isGenerating = false
    @MainActor @Published var generationProgress: Double = 0
    
    // API service (injected)
    var apiService: ZImageAPIService?

    // Current generation task (cancellable)
    private var generationTask: Task<UIImage?, Error>?

    init() {
        // API-only mode, no local models
    }

    // MARK: - CANCEL
    func cancelGeneration() {
        // Cancel any running generation task and reset UI state
        generationTask?.cancel()
        generationTask = nil
        Task { @MainActor in
            self.isGenerating = false
            self.generationProgress = 0
        }
    }

    // MARK: - GENERATE (API-only)
    func generate(prompt: String, negativePrompt: String, stepCount: Int, guidanceScale: Float, seed: UInt32) async -> UIImage? {
        return await generateViaAPI(
            prompt: prompt,
            negativePrompt: negativePrompt,
            stepCount: stepCount,
            seed: seed
        )
    }

    
    // MARK: - API GENERATION
    private func generateViaAPI(prompt: String, negativePrompt: String, stepCount: Int, seed: UInt32) async -> UIImage? {
        guard let apiService = apiService, apiService.isConfigured else {
            print("❌ API service not configured")
            return nil
        }
        
        // Update UI state
        await MainActor.run { isGenerating = true }

        // Create a cancellable task for the generation
        generationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }
            // Combine prompt with negative prompt
            let fullPrompt = negativePrompt.isEmpty ? prompt : "\(prompt). Negative: \(negativePrompt)"
            return try await apiService.generateWithPolling(
                prompt: fullPrompt,
                width: 512,
                height: 512,
                steps: 9,
                seed: Int(seed),
                progressCallback: { progress in
                    Task { @MainActor in
                        self.generationProgress = Double(progress) / 100.0
                    }
                }
            )
        }

        do {
            let image = try await generationTask?.value
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return image
        } catch is CancellationError {
            // Task was cancelled by user
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return nil
        } catch {
            print("❌ API generation failed:", error.localizedDescription)
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return nil
        }
    }
    
    // MARK: - GENERATE INPAINT
    func generateInpaint(
        prompt: String,
        negativePrompt: String,
        originalImage: UIImage,
        maskImage: UIImage,
        stepCount: Int,
        guidanceScale: Float,
        seed: UInt32
    ) async -> UIImage? {
        // API doesn't support inpainting yet
        // For now, just do text-to-image generation
        print("⚠️ Inpainting not supported via API, using text-to-image")
        return await generateViaAPI(
            prompt: prompt,
            negativePrompt: negativePrompt,
            stepCount: stepCount,
            seed: seed
        )
    }
    
    // MARK: - GENERATE STYLE TRANSFER (simplified to text-to-image)
    func generateStyleTransfer(
        prompt: String,
        negativePrompt: String,
        originalImage: UIImage,
        maskImage: UIImage,
        stepCount: Int,
        guidanceScale: Float,
        seed: UInt32,
        strength: Float = 0.8,
        preserveColor: Bool = false,
        cfg: Double? = nil
    ) async -> UIImage? {
        guard let apiService = apiService, apiService.isConfigured else {
            print("❌ API service not configured")
            return nil
        }

        // Update UI state
        await MainActor.run { isGenerating = true }

        do {
            let styleDescription = negativePrompt.isEmpty ? prompt : "\(prompt). Avoid: \(negativePrompt)"

            let generated = try await apiService.styleTransferWithPolling(
                contentImage: originalImage,
                styleDescription: styleDescription,
                strength: Double(strength),
                preserveColor: preserveColor,
                outputWidth: 512,
                outputHeight: 512,
                promptOverride: prompt,
                steps: 9,
                cfg: cfg,
                progressCallback: { progress in
                    Task { @MainActor in
                        self.generationProgress = Double(progress) / 100.0
                    }
                }
            )

            // Normalize orientation to avoid rotated results
            let normOriginal = originalImage.normalizedImage()
            let normMask = maskImage.normalizedImage()

            // Resize generated to match original for compositing
            let resizedGenerated = resizeImage(generated, targetSize: normOriginal.size) ?? generated

            let composed = composite(original: normOriginal, generated: resizedGenerated, mask: normMask)

            await MainActor.run { isGenerating = false }
            return composed

        } catch {
            print("❌ Style transfer (masked) failed:", error.localizedDescription)
            await MainActor.run { isGenerating = false }
            return nil
        }
    }
    
    // MARK: - GENERATE STYLE TRANSFER (Img2Img overload)
    func generateStyleTransfer(
        prompt: String,
        negativePrompt: String,
        originalImage: UIImage,
        strength: Float,
        stepCount: Int,
        seed: UInt32,
        preserveColor: Bool = false,
        cfg: Double? = nil
    ) async -> UIImage? {
        guard let apiService = apiService, apiService.isConfigured else {
            print("❌ API service not configured")
            return nil
        }
        
        // Update UI state
        await MainActor.run { isGenerating = true }
        
        // Cancellable task for img2img style transfer
        await MainActor.run { isGenerating = true }
        generationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }
            do {
                // Combine prompt with negative prompt for style description
                let styleDescription = negativePrompt.isEmpty ? prompt : "\(prompt). Avoid: \(negativePrompt)"
                
                let image = try await apiService.styleTransferWithPolling(
                    contentImage: originalImage,
                    styleDescription: styleDescription,
                    strength: Double(strength),
                    preserveColor: preserveColor,
                    outputWidth: 512,
                    outputHeight: 512,
                    promptOverride: prompt,
                    steps: 9,
                    cfg: cfg,
                    progressCallback: { progress in
                        Task { @MainActor in
                            self.generationProgress = Double(progress) / 100.0
                        }
                    }
                )
                return image
            } catch {
                if Task.isCancelled { return nil }
                throw error
            }
        }

        do {
            let image = try await generationTask?.value
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return image
        } catch is CancellationError {
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return nil
        } catch {
            print("❌ Style transfer failed:", error.localizedDescription)
            await MainActor.run { isGenerating = false }
            generationTask = nil
            return nil
        }
    }

    // MARK: - Helpers
    // Resize image to target size (opaque RGB)
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
            // Aspect fill
            let widthRatio = targetSize.width / image.size.width
            let heightRatio = targetSize.height / image.size.height
            let scaleFactor = max(widthRatio, heightRatio)
            let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
            let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2,
                                 y: (targetSize.height - scaledSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    // Composite generated image over original using mask (mask white keeps generated)
    private func composite(original: UIImage, generated: UIImage, mask: UIImage) -> UIImage? {
        let size = original.size
        UIGraphicsBeginImageContextWithOptions(size, false, original.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // 1. Draw original
        original.draw(in: CGRect(origin: .zero, size: size))

        // 2. Clip to mask (mask white keeps generated)
        if let cgMask = mask.cgImage, let cgGen = generated.cgImage {
            ctx.saveGState()
            // Flip context for CG coordinate system
            ctx.scaleBy(x: 1.0, y: -1.0)
            ctx.translateBy(x: 0, y: -size.height)
            let rect = CGRect(origin: .zero, size: size)
            ctx.clip(to: rect, mask: cgMask)
            ctx.draw(cgGen, in: rect)
            ctx.restoreGState()
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
