import Foundation
import CoreML
import StableDiffusion
import UIKit
import SwiftUI

@MainActor
class ModelManager: ObservableObject {
    
    // New published property to track the generation state in the UI
    @Published var isGenerating = false
    
    var pipeline: StableDiffusionPipeline?

    init() {
        // Start loading the pipeline asynchronously
        Task { await load() }
    }

    // MARK: - CoreML Cache Management
    
    // Function to get the estimated path where the CoreML cache files are stored
    private func getCoreMLCacheDirectoryPath() -> URL? {
        // CoreML compiles models into a cache directory specific to the app.
        let fileManager = FileManager.default
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // This is the safest approach to target the general area where the compiled BNNS graphs live.
        return cachesDirectory
    }

    /// Clears the compiled CoreML model cache from disk, freeing up gigabytes of space.
    /// The pipeline will need to be recompiled (re-initialized) on the next run.
    func clearCache() {
        guard let cachesURL = getCoreMLCacheDirectoryPath() else {
            print("🔴 Error: Could not locate caches directory.")
            return
        }

        let fileManager = FileManager.default
        do {
            // Get all contents of the Caches directory
            let cacheContents = try fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil, options: [])
            
            var totalFilesDeleted = 0
            
            // Iterate and delete all sub-items. This aggressively clears the 22GB+ cache.
            for itemURL in cacheContents {
                try fileManager.removeItem(at: itemURL)
                totalFilesDeleted += 1
            }
            
            // Set pipeline to nil so it forces a reload/recompile on the next use
            self.pipeline = nil
            
            print("✅ Successfully cleared \(totalFilesDeleted) items from the CoreML cache. Pipeline reset.")
        } catch {
            print("❌ Failed to clear cache: \(error.localizedDescription)")
        }
    }


    func load() async {
        do {
            // Reverting to the robust path finding method that resolved previous errors.
            // 1. Get the path as a String (safer for resource directories)
            guard let modelPath = Bundle.main.path(forResource: "compiled", ofType: nil) else {
                print("🔴 FATAL ERROR: Could not find 'compiled' directory path in the app bundle.")
                print("Please ensure the 'compiled' folder is added to your Xcode project as a blue 'Folder Reference'.")
                return
            }
            
            // 2. Convert the found path string into a URL
            let modelURL = URL(fileURLWithPath: modelPath)
            
            // 3. Verify the item at the path is actually a directory (optional but good practice)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: modelPath, isDirectory: &isDirectory) && isDirectory.boolValue else {
                print("🔴 FATAL ERROR: Path was found, but 'compiled' is not a valid directory.")
                return
            }

            // Configuration for CoreML compute units (keeping your updated settings)
            let resources = try MLModelConfiguration()
            resources.computeUnits = .cpuAndNeuralEngine
            resources.allowLowPrecisionAccumulationOnGPU = true

            pipeline = try StableDiffusionPipeline(
                resourcesAt: modelURL,
                controlNet: [],
                configuration: resources,
                reduceMemory: true
            )

            print("Pipeline loaded successfully")

        } catch {
            print("Failed to load pipeline: \(error.localizedDescription)")
        }
    }

    func generate(prompt: String) async -> UIImage? {

        // Check if the pipeline has finished loading
        guard let pipeline else {
            print("Pipeline not ready")
            return nil
        }
        
        // --- START GENERATION ---
        isGenerating = true

        // Configure the generation settings (keeping your settings)
        var config = StableDiffusionPipeline.Configuration(prompt: prompt)
        print("starting image generation")
        let randomSeed = UInt32.random(in: 0...UInt32.max)
        config.seed = randomSeed
        print("Using seed: \(randomSeed)")
        // config.stepCount = 30 // Commented out to use default steps for speed
        config.guidanceScale = 7.5
        
        do {
            // Execute the generation process
            let out = try await pipeline.generateImages(configuration: config)

            // --- END GENERATION (SUCCESS) ---
            isGenerating = false

            guard let firstImageOptional = out.first, let cg = firstImageOptional else {
                print("No image generated or the resulting image was nil.")
                return nil
            }
            
            print("Image generated successfully!")
            return UIImage(cgImage: cg)

        } catch {
            // --- END GENERATION (FAILURE) ---
            isGenerating = false
            print("Generation failed: \(error)")
            return nil
        }
    }
}
