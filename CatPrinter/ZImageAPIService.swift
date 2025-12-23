import Foundation
import UIKit

/// Service for interacting with the zimage-server API
/// Supports async image generation with job polling
class ZImageAPIService: ObservableObject {
    
    // MARK: - Configuration
    @Published var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "zimageBaseURL")
        }
    }
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "zimageAPIKey")
        }
    }
    
    @Published var isConfigured: Bool = false
    
    // MARK: - Models
    struct GenerateRequest: Codable {
        let prompt: String
        let width: Int
        let height: Int
        let steps: Int
        let seed: Int?
    }
    
    struct StyleTransferRequest: Codable {
        let content_image: String  // base64
        let style_description: String
        let strength: Double
        let preserve_color: Bool
        let output_width: Int
        let output_height: Int
        let prompt_override: String?
        let steps: Int?
        let cfg: Double?
    }
    
    struct AsyncJobResponse: Codable {
        let job_id: String
    }
    
    struct JobStatusResponse: Codable {
        let status: String
        let progress: Int
        let download_url: String?
        let error: String?
    }
    
    struct APIKeyResponse: Codable {
        let api_key: String
        let message: String
    }
    
    struct CreateAPIKeyRequest: Codable {
        let admin_token: String
    }
    
    struct StatusResponse: Codable {
        let api_name: String?
        let version: String?
        let authentication_required: Bool?
        let message: String?
    }
    
    // MARK: - Init
    init() {
        // Load saved configuration
        if let savedURL = UserDefaults.standard.string(forKey: "zimageBaseURL") {
            self.baseURL = savedURL
        } else {
            self.baseURL = "http://localhost:8000"
        }
        
        if let savedKey = UserDefaults.standard.string(forKey: "zimageAPIKey") {
            self.apiKey = savedKey
            self.isConfigured = !savedKey.isEmpty
        } else {
            self.apiKey = ""
            self.isConfigured = false
        }
    }
    
    // MARK: - API Key Management
    
    /// Create a new API key using admin token
    func createAPIKey(adminToken: String) async throws -> String {
        let endpoint = "\(baseURL)/admin/create-api-key"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CreateAPIKeyRequest(admin_token: adminToken)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let apiKeyResponse = try JSONDecoder().decode(APIKeyResponse.self, from: data)
        
        // Save the API key
        await MainActor.run {
            self.apiKey = apiKeyResponse.api_key
            self.isConfigured = true
        }
        
        return apiKeyResponse.api_key
    }
    
    /// Check API status
    func checkStatus() async throws -> StatusResponse {
        let endpoint = "\(baseURL)/status"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }
    
    // MARK: - Image Generation
    
    /// Generate image asynchronously (returns job ID immediately)
    func generateAsync(
        prompt: String,
        width: Int = 1024,
        height: Int = 1024,
        steps: Int = 9,
        seed: Int? = nil
    ) async throws -> String {
        let endpoint = "\(baseURL)/generate_async"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let requestBody = GenerateRequest(
            prompt: prompt,
            width: width,
            height: height,
            steps: steps,
            seed: seed
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw APIError.forbidden
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let jobResponse = try JSONDecoder().decode(AsyncJobResponse.self, from: data)
        return jobResponse.job_id
    }
    
    /// Poll job status
    func getJobStatus(jobId: String) async throws -> JobStatusResponse {
        let endpoint = "\(baseURL)/job/\(jobId)"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(JobStatusResponse.self, from: data)
    }
    
    /// Download generated image
    func downloadImage(jobId: String) async throws -> UIImage {
        let endpoint = "\(baseURL)/job/\(jobId)/image"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let image = UIImage(data: data) else {
            throw APIError.invalidImageData
        }
        
        return image
    }
    
    /// Submit async style transfer job
    func styleTransferAsync(
        contentImage: UIImage,
        styleDescription: String,
        strength: Double = 0.8,
        preserveColor: Bool = false,
        outputWidth: Int = 512,
        outputHeight: Int = 512,
        promptOverride: String? = nil,
        steps: Int? = 9,
        cfg: Double? = nil
    ) async throws -> String {
        let endpoint = "\(baseURL)/style-transfer"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        // Normalize orientation then convert image to base64
        let normalizedImage = contentImage.normalizedImage()
        guard let imageData = normalizedImage.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidImageData
        }
        let base64Image = imageData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        // Clamp strength to [0.0, 1.0] as required by zimage-server
        let clampedStrength = min(max(strength, 0.0), 1.0)

        let requestBody = StyleTransferRequest(
            content_image: base64Image,
            style_description: styleDescription,
            strength: clampedStrength,
            preserve_color: preserveColor,
            output_width: outputWidth,
            output_height: outputHeight,
            prompt_override: promptOverride,
            steps: steps,
            cfg: cfg
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw APIError.forbidden
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let jobResponse = try JSONDecoder().decode(AsyncJobResponse.self, from: data)
        return jobResponse.job_id
    }
    
    /// Generate image with polling (convenience method)
    /// Polls until job completes and returns the image
    func generateWithPolling(
        prompt: String,
        width: Int = 1024,
        height: Int = 1024,
        steps: Int = 9,
        seed: Int? = nil,
        progressCallback: ((Int) -> Void)? = nil
    ) async throws -> UIImage {
        
        // Submit job
        let jobId = try await generateAsync(
            prompt: prompt,
            width: width,
            height: height,
            steps: steps,
            seed: seed
        )
        
        // Poll for completion
        while true {
            let status = try await getJobStatus(jobId: jobId)
            
            // Update progress
            progressCallback?(status.progress)
            
            switch status.status {
            case "done":
                // Download and return image
                return try await downloadImage(jobId: jobId)
                
            case "failed":
                throw APIError.generationFailed(error: status.error ?? "Unknown error")
                
            case "pending", "running":
                // Wait before polling again
                try await Task.sleep(nanoseconds: 5_000_000_000) // 2 seconds
                
            default:
                throw APIError.unknownStatus(status: status.status)
            }
        }
    }
    
    /// Style transfer with polling (convenience method)
    /// Polls until job completes and returns the styled image
    func styleTransferWithPolling(
        contentImage: UIImage,
        styleDescription: String,
        strength: Double = 0.8,
        preserveColor: Bool = false,
        outputWidth: Int = 512,
        outputHeight: Int = 512,
        promptOverride: String? = nil,
        steps: Int? = 9,
        cfg: Double? = nil,
        progressCallback: ((Int) -> Void)? = nil
    ) async throws -> UIImage {
        
        // Submit job
        let jobId = try await styleTransferAsync(
            contentImage: contentImage,
            styleDescription: styleDescription,
            strength: strength,
            preserveColor: preserveColor,
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            promptOverride: promptOverride,
            steps: steps,
            cfg: cfg
        )
        
        // Poll for completion
        while true {
            let status = try await getJobStatus(jobId: jobId)
            
            // Update progress
            progressCallback?(status.progress)
            
            switch status.status {
            case "done":
                // Download and return image
                return try await downloadImage(jobId: jobId)
                
            case "failed":
                throw APIError.generationFailed(error: status.error ?? "Unknown error")
                
            case "pending", "running":
                // Wait before polling again
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
            default:
                throw APIError.unknownStatus(status: status.status)
            }
        }
    }
    
    // MARK: - Error Types
    enum APIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case unauthorized
        case forbidden
        case httpError(statusCode: Int)
        case invalidImageData
        case generationFailed(error: String)
        case unknownStatus(status: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid server response"
            case .unauthorized:
                return "Missing or invalid API key"
            case .forbidden:
                return "Access forbidden - check API key"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .invalidImageData:
                return "Could not decode image data"
            case .generationFailed(let error):
                return "Generation failed: \(error)"
            case .unknownStatus(let status):
                return "Unknown job status: \(status)"
            }
        }
    }
}
