//
//  OpenAIManager.swift
//  Coacher
//
//  Created by Rebecca Clarke on 9/6/25.
//

import Foundation
import SwiftUI
import SwiftData
import OpenAI

/// OpenAI Manager for direct API integration
@MainActor
class OpenAIManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chatHistory: [LLMMessage] = []
    
    // OpenAI Configuration
    private var openAI: OpenAI?
    private let maxTokens = 2000
    private let temperature = 0.7
    private let model = "gpt-4o-mini" // Cost-effective model for coaching
    
    init() {
        chatHistory = []
        setupOpenAI()
    }
    
    // MARK: - Setup
    
    private func setupOpenAI() {
        if let apiKey = KeychainManager.shared.getOpenAIKey(), !apiKey.isEmpty {
            openAI = OpenAI(apiToken: apiKey)
            isModelLoaded = true
            print("🌐 OpenAIManager: API key found, model ready")
        } else {
            errorMessage = "OpenAI API key not found. Please add your API key in Settings."
            isModelLoaded = false
            print("🌐 OpenAIManager: No API key found")
        }
    }
    
    // MARK: - Model Management
    
    /// Load the OpenAI model
    func loadModel() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            print("🌐 OpenAIManager: Starting model loading...")
        }
        
        // Simulate a realistic loading time for online AI
        // This gives users feedback that something is happening
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        setupOpenAI()
        
        await MainActor.run {
            isLoading = false
            print("🌐 OpenAIManager: Model loading complete, isModelLoaded: \(isModelLoaded)")
        }
    }
    
    /// Generate a response using OpenAI
    func generateResponse(for userMessage: String, context: String = "") async -> String {
        guard let openAI = openAI else {
            return "OpenAI not configured. Please add your API key in Settings."
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // For now, use a simple approach - just return a mock response
            // TODO: Implement proper OpenAI API integration
            let response = """
            I'm your AI weight loss coach! I'm here to help you build healthier habits and achieve your goals.
            
            While I'm still getting set up with the advanced AI features, I can help you with:
            • Setting realistic goals
            • Building healthy habits
            • Overcoming challenges
            • Staying motivated
            
            What would you like to work on today?
            """
            
            await MainActor.run {
                isLoading = false
            }
            
            return response
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "OpenAI API error: \(error.localizedDescription)"
            }
            
            return "I'm sorry, I encountered an error. Please try again or check your internet connection."
        }
    }
    
    // MARK: - Message Management
    
    /// Save a message to chat history
    func saveMessage(_ content: String, isUser: Bool) async {
        let message = LLMMessage(
            role: isUser ? .user : .assistant,
            content: content,
            timestamp: Date()
        )
        
        await MainActor.run {
            chatHistory.append(message)
        }
    }
    
    /// Clear chat history
    func clearHistory() {
        chatHistory.removeAll()
    }
    
    /// Get current token usage (estimated)
    func getCurrentTokenUsage() -> Int {
        // Rough estimation: 1 token ≈ 4 characters
        return chatHistory.reduce(0) { total, message in
            total + message.content.count / 4
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Unload model (no-op for OpenAI as it's always available)
    func unloadModel() async {
        // OpenAI doesn't need to be "unloaded" - it's always available
        await MainActor.run {
            isModelLoaded = false
        }
    }
}
