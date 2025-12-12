import Foundation
import CoreML
import StableDiffusion
import UIKit
import SwiftUI

class ModelManager: ObservableObject {

    // UI state — must be marked @MainActor
    @MainActor @Published var isGenerating = false
    @MainActor @Published var isPipelineReady = false
    @MainActor @Published var modelMissing = false
    @MainActor @Published var generationProgress: Double = 0

    private var pipeline: StableDiffusionPipeline?
    private var generationTask: Task<UIImage?, Error>?

    init() {
        Task { await load() }
    }
    
    // Call this to retry loading (e.g. after download)
    func retryLoad() {
        Task { await load() }
    }

    // MARK: - LOAD (background, non-main)
    func load() async {
        // CHANGED: Load from Documents directory "compiled" folder
        // This allows models to be downloaded/updated post-install.
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelURL = docURL.appendingPathComponent("compiled")

        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            await MainActor.run {
                self.modelMissing = true
                self.isPipelineReady = false
            }
            return
        }
        
        // Reset missing flag if found
        await MainActor.run {
            self.modelMissing = false
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            
            // Load heavy pipeline OFF main thread
            let loadedPipeline = try await Task.detached {
                try StableDiffusionPipeline(
                    resourcesAt: modelURL,
                    controlNet: [],
                    configuration: config,
                    reduceMemory: true
                )
            }.value

            // Only assignment must happen on main thread
            await MainActor.run {
                self.pipeline = loadedPipeline
                self.isPipelineReady = true
                print("✅ Pipeline loaded")
            }

        } catch {
            print("❌ Pipeline load failed:", error.localizedDescription)
            // Could set an error state here too
        }
    }

    // MARK: - CANCEL
    func cancelGeneration() {
        generationTask?.cancel()
        Task { @MainActor in isGenerating = false }
    }

    // MARK: - GENERATE (runs off main thread)
    func generate(prompt: String, negativePrompt: String, stepCount: Int, guidanceScale: Float, seed: UInt32) async -> UIImage? {

        guard let pipeline else {
            print("❌ Pipeline not ready")
            return nil
        }

        // Cancel object
        generationTask?.cancel()

        // Update UI state
        await MainActor.run { isGenerating = true }

        // Create full pipeline configuration
        var cfg = StableDiffusionPipeline.Configuration(prompt: prompt)
        cfg.seed = seed
        cfg.stepCount = stepCount
        cfg.guidanceScale = guidanceScale
        cfg.negativePrompt = negativePrompt
        cfg.schedulerType = .pndmScheduler
        cfg.imageCount = 1
        cfg.useDenoisedIntermediates = false

        // DETACHED = NOT tied to main actor
        generationTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }

            do {
                let outputs = try pipeline.generateImages(
                    configuration: cfg,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.generationProgress = Double(progress.step) / Double(progress.stepCount)
                        }
                        return Task.isCancelled == false
                    }
                )

                if Task.isCancelled { return nil }
                guard let cg = outputs.first else { return nil }

                return UIImage(cgImage: cg!)

            } catch is CancellationError {
                print("🛑 Cancelled")
                return nil

            } catch {
                print("❌ Error:", error.localizedDescription)
                return nil
            }
        }

        let img = try? await generationTask?.value

        await MainActor.run { isGenerating = false }

        return img
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

        guard let pipeline else { return nil }

        generationTask?.cancel()
        await MainActor.run { isGenerating = true }

        var cfg = StableDiffusionPipeline.Configuration(prompt: prompt)
        cfg.seed = seed
        cfg.stepCount = stepCount
        cfg.guidanceScale = guidanceScale
        cfg.negativePrompt = negativePrompt
        cfg.imageCount = 1
        cfg.schedulerType = .pndmScheduler // Or whatever plays nice with inpainting
        
        // Resize original and mask to 512×512 opaque RGB
        let targetSize = CGSize(width: 512, height: 512)
        
        guard let resizedOriginal = resizeImage(originalImage, targetSize: targetSize),
              let cgOriginal = resizedOriginal.cgImage else {
            print("❌ Inpaint Error: could not resize original image")
            await MainActor.run { isGenerating = false }
            return nil
        }
        cfg.startingImage = cgOriginal
        cfg.strength = 0.8   // high strength for effective inpainting
        
        // Store the resized mask for later compositing
        let resizedMask = resizeImage(maskImage, targetSize: targetSize) ?? maskImage

        generationTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }
            do {
                let outputs = try pipeline.generateImages(
                    configuration: cfg,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.generationProgress = Double(progress.step) / Double(progress.stepCount)
                        }
                        return Task.isCancelled == false
                    }
                )
                if Task.isCancelled { return nil }
                
                guard let generatedCG = outputs.first.flatMap({ $0 }) else { return nil }
                let generatedImage = UIImage(cgImage: generatedCG)
                
                // MANUAL COMPOSITION: Blend Generated over Original using Mask
                // Use the resized mask we prepared earlier
                return self.composite(original: resizedOriginal, generated: generatedImage, mask: resizedMask)
                
            } catch {
                print("❌ Inpaint Error:", error.localizedDescription)
                return nil
            }
        }

        let img = try? await generationTask?.value
        await MainActor.run { isGenerating = false }
        return img
    }
    
    private func composite(original: UIImage, generated: UIImage, mask: UIImage) -> UIImage? {
        // Ensure all are same size/scale
        let size = original.size
        UIGraphicsBeginImageContextWithOptions(size, false, original.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        // 1. Draw Original
        original.draw(in: CGRect(origin: .zero, size: size))
        
        // 2. Clip to Mask
        // Mask: White keeps, Black cuts (or vice versa depending on CG behavior).
        // CGContextClipToMask: "The mask map is treated as an alpha mask"
        // If our mask is grayscale, we might need to be careful.
        // Let's rely on standard masking:
        // We want to draw 'generated' ONLY where mask is WHITE.
        
        if let cgMask = mask.cgImage {
            // Unflip coords for CG
            ctx.scaleBy(x: 1.0, y: -1.0)
            ctx.translateBy(x: 0, y: -size.height)
            
            // Define clipping rect (full size)
            let rect = CGRect(origin: .zero, size: size)
            
            // Masking in CG: "The result of the masking operation is the intersection of the mask and the drawing."
            // CGContextClipToMask expects a mask where the opaque parts are visible?
            ctx.clip(to: rect, mask: cgMask)
            
            // Draw Generated (flipped back? no, we are already flipped)
            // generated.draw(in: ...) uses UIKit coords (unflipped inside).
            // Since we manually flipped CTM, we should draw CGImage directly.
            if let cgGen = generated.cgImage {
                ctx.draw(cgGen, in: rect)
            }
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    // MARK: - GENERATE STYLE TRANSFER (Img2Img)
    func generateStyleTransfer(
        prompt: String,
        negativePrompt: String,
        originalImage: UIImage,
        strength: Float, // 0.0 to 1.0. Lower = closer to original. Higher = more hallucination.
        stepCount: Int,
        guidanceScale: Float,
        seed: UInt32
    ) async -> UIImage? {

        guard let pipeline else { return nil }

        generationTask?.cancel()
        await MainActor.run { isGenerating = true }

        var cfg = StableDiffusionPipeline.Configuration(prompt: prompt)
        cfg.negativePrompt = negativePrompt
        cfg.seed = seed
        cfg.stepCount = stepCount
        cfg.guidanceScale = guidanceScale
        cfg.imageCount = 1
        cfg.schedulerType = .pndmScheduler // Using available scheduler
        
        // Resize image to 512×512 opaque RGB for the model
        if let resized = resizeImage(originalImage, targetSize: CGSize(width: 512, height: 512)),
           let cgResized = resized.cgImage {
            cfg.startingImage = cgResized
            cfg.strength = strength
        } else {
            // Fallback: plain white 512×512 image (guarantees correct format)
            print("⚠️ Style Transfer: Failed to resize image, using white placeholder")
            let placeholder = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512)).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: CGSize(width: 512, height: 512)))
            }
            if let cgPlaceholder = placeholder.cgImage {
                cfg.startingImage = cgPlaceholder
                cfg.strength = strength
            } else {
                await MainActor.run { isGenerating = false }
                return nil
            }
        }

        generationTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }
            do {
                let outputs = try pipeline.generateImages(
                    configuration: cfg,
                    progressHandler: { progress in
                        Task { @MainActor in
                            self.generationProgress = Double(progress.step) / Double(progress.stepCount)
                        }
                        return Task.isCancelled == false
                    }
                )
                if Task.isCancelled { return nil }
                return outputs.first.flatMap { UIImage(cgImage: $0!) }
            } catch {
                print("❌ Style Transfer Error:", error.localizedDescription)
                return nil
            }
        }

        let img = try? await generationTask?.value
        await MainActor.run { isGenerating = false }
        return img
    }
    
    // MARK: - Helper: Resize Image (opaque RGB)
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        // Ensure we render without alpha to avoid encoder issues
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true // no alpha channel
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            // Fill background with white
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
            // Compute scaling to fill target size (aspect fill)
            let widthRatio = targetSize.width / image.size.width
            let heightRatio = targetSize.height / image.size.height
            let scaleFactor = max(widthRatio, heightRatio)
            let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
            // Center the scaled image
            let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2,
                                 y: (targetSize.height - scaledSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }
}
