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
            print("❌ 'compiled' folder not found at \(modelURL.path)")
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
                    progressHandler: { _ in
                        Task.isCancelled == false
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
}
