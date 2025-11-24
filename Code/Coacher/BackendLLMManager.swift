import Foundation
import SwiftUI
import SwiftData

/// Backend proxy-based LLM Manager for secure AI responses
@MainActor
class BackendLLMManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chatHistory: [LLMMessage] = []
    
    // Backend Configuration
    private let backendURL: String
    private let maxTokens = 2000
    private let temperature = 0.7
    
    // Response structure for backend API
    private struct ChatResponse: Codable {
        let response: String
        let usage: TokenUsage
        let model: String
        let timestamp: String
        let isCrisis: Bool?  // Optional: only present in crisis responses
        let resources: CrisisResources?  // Optional: only present in crisis responses
    }
    
    private struct CrisisResources: Codable {
        let suicideHotline: String?
        let crisisTextLine: String?
        let emergency: String?
    }
    
    private struct TokenUsage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
    
    init(backendURL: String = "https://lightertomorrow.com") {
        self.backendURL = backendURL
        chatHistory = []
    }
    
    // MARK: - Model Management
    
    /// Load the backend model (always ready)
    func loadModel() async {
        await MainActor.run {
            errorMessage = nil
            print("🌐 BackendLLMManager: Starting backend connectivity check...")
            print("🌐 BackendLLMManager: Backend URL: \(backendURL)")
        }
        
        // Test backend connectivity (no loading state needed for online AI)
        let isBackendAvailable = await testBackendConnection()
        
        await MainActor.run {
            isModelLoaded = isBackendAvailable
            if !isBackendAvailable {
                errorMessage = "Backend service unavailable. Please check your internet connection."
                print("🌐 BackendLLMManager: Backend connection failed - API key may not be configured in Netlify environment variables")
            } else {
                print("🌐 BackendLLMManager: Backend connection successful - API key found in Netlify environment variables")
            }
            print("🌐 BackendLLMManager: Backend ready, isModelLoaded: \(isModelLoaded)")
        }
    }
    
    /// Generate a response using the backend proxy
    func generateResponse(for userMessage: String, context: String = "") async -> String {
        guard isModelLoaded else {
            return "Backend model not loaded yet. Please wait..."
        }
        
        // Check usage limit before making request
        let usageTracker = UsageTracker.shared
        guard await usageTracker.canMakeRequest() else {
            let remainingTokens = await usageTracker.getRemainingTokens()
            let renewalDate = await usageTracker.getRenewalDateString()
            return "You've reached your monthly token limit (100,000 tokens). Your usage will reset on \(renewalDate). Please try again after the reset."
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        // Save user message
        await saveMessage(userMessage, isUser: true)
        
        do {
            let (response, tokenUsage) = try await callBackendAPI(message: userMessage, context: context)
            
            // Record token usage
            await usageTracker.recordUsage(inputTokens: tokenUsage.promptTokens, outputTokens: tokenUsage.completionTokens)
            
            // Save AI response
            await saveMessage(response, isUser: false)
            
            await MainActor.run {
                isLoading = false
            }
            
            return response
        } catch {
            let errorMessage = "Error generating response: \(error.localizedDescription)"
            
            await MainActor.run {
                self.errorMessage = errorMessage
                isLoading = false
            }
            
            return errorMessage
        }
    }
    
    // MARK: - Backend API Communication
    
    private func testBackendConnection() async -> Bool {
        guard let url = URL(string: "\(backendURL)/.netlify/functions/health") else { 
            print("🌐 BackendLLMManager: Invalid health check URL: \(backendURL)/.netlify/functions/health")
            return false 
        }
        
        print("🌐 BackendLLMManager: Testing backend connection to: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 BackendLLMManager: Health check response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🌐 BackendLLMManager: Health check response body: \(responseString)")
                }
                return httpResponse.statusCode == 200
            }
        } catch {
            print("🌐 BackendLLMManager: Backend connection test failed: \(error)")
            print("🌐 BackendLLMManager: Error details: \(error.localizedDescription)")
        }
        
        return false
    }
    
    private func callBackendAPI(message: String, context: String) async throws -> (String, TokenUsage) {
        guard let url = URL(string: "\(backendURL)/.netlify/functions/chat") else {
            throw BackendError.invalidURL
        }
        
        print("🌐 BackendLLMManager: Calling chat API at: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Coacher-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let requestBody = [
            "message": message,
            "context": context,
            "maxTokens": maxTokens,
            "temperature": temperature
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw BackendError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        print("🌐 BackendLLMManager: Chat API response status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            print("🌐 BackendLLMManager: Chat API success - tokens used: \(chatResponse.usage.totalTokens)")
            return (chatResponse.response, chatResponse.usage)
            
        case 429:
            print("🌐 BackendLLMManager: Rate limited by OpenAI API")
            throw BackendError.rateLimited
            
        case 400:
            print("🌐 BackendLLMManager: Bad request - check API key configuration")
            if let errorData = String(data: data, encoding: .utf8) {
                print("🌐 BackendLLMManager: Error response: \(errorData)")
            }
            throw BackendError.badRequest
            
        case 500:
            print("🌐 BackendLLMManager: Server error - API key may be missing or invalid")
            if let errorData = String(data: data, encoding: .utf8) {
                print("🌐 BackendLLMManager: Error response: \(errorData)")
            }
            throw BackendError.serverError
            
        default:
            print("🌐 BackendLLMManager: Unknown error status: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("🌐 BackendLLMManager: Error response: \(errorData)")
            }
            throw BackendError.unknownError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Message Management
    
    private func saveMessage(_ content: String, isUser: Bool) async {
        await MainActor.run {
            let role: Role = isUser ? .user : .assistant
            let message = LLMMessage(
                role: role,
                content: content,
                timestamp: Date()
            )
            chatHistory.append(message)
        }
    }
    
    // MARK: - Model Status
    
    var modelStatus: String {
        if isLoading {
            return "Processing your message..."
        } else if isModelLoaded {
            return "Enhanced Cloud AI Ready (2000 token limit)"
        } else {
            return "Backend service unavailable"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Cleanup
    
    func unloadModel() async {
        await MainActor.run {
            isModelLoaded = false
            chatHistory.removeAll()
        }
    }
    
    // MARK: - Testing Utilities
    
    /// Get current token usage for testing (rough estimate for display)
    func getCurrentTokenUsage() -> Int {
        let totalText = chatHistory.map { $0.content }.joined()
        return totalText.count / 4 // Rough token estimation
    }
}

// MARK: - Backend Errors

enum BackendError: LocalizedError {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case rateLimited
    case badRequest
    case serverError
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from backend"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .badRequest:
            return "Invalid request. Please check your input."
        case .serverError:
            return "Backend server error. Please try again later."
        case .unknownError(let code):
            return "Unknown error (code: \(code))"
        }
    }
}
