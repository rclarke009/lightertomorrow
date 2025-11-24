import Foundation
import SwiftUI
import SwiftData
import MLX
import MLXNN
import MLXOptimizers
import MLXLLM
import MLXLMCommon
import Hub

/// MLX-based Local LLM Manager for real on-device AI responses
@MainActor
class MLXLLMManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chatHistory: [LLMMessage] = []

    // MLX Configuration
    private let maxTokens = 2000
    private let temperature = 0.7
    private let topP = 0.9

    // Real MLX Model Management
    private var modelContainer: MLXLMCommon.ModelContainer?
    private var isInitialized = false
    private var modelName = "MLX Local AI"
    
    // Available models for the coaching app
    private let availableModels: [LMModel] = [
        LMModel(name: "llama3.2:1b", configuration: LLMRegistry.llama3_2_1B_4bit, type: LMModel.ModelType.llm),
        LMModel(name: "phi3.5", configuration: LLMRegistry.phi3_5_4bit, type: LMModel.ModelType.llm),
        LMModel(name: "qwen2.5:1.5b", configuration: LLMRegistry.qwen2_5_1_5b, type: LMModel.ModelType.llm),
        LMModel(name: "smolLM:135m", configuration: LLMRegistry.smolLM_135M_4bit, type: LMModel.ModelType.llm),
    ]
    
    // Currently selected model (default to smallest for mobile)
    private var selectedModel: LMModel {
        availableModels.first { $0.name == "llama3.2:1b" } ?? availableModels.first!
    }

    init() {
        chatHistory = []
    }
    
    // MARK: - LMModel Definition
    
    /// Represents a language model configuration for the coaching app
    struct LMModel {
        let name: String
        let configuration: MLXLMCommon.ModelConfiguration
        let type: ModelType
        
        enum ModelType {
            case llm
        }
    }

    // MARK: - Model Management

    /// Load the local AI model
    func loadModel() async {
        // Check if model is already loaded
        if isModelLoaded && modelContainer != nil {
            print("🤖 MLXLLMManager: Model already loaded, skipping...")
            return
        }
        
        print("🤖 MLXLLMManager: Starting model loading...")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            print("🤖 MLXLLMManager: isLoading set to true")
        }

        do {
            if !isInitialized {
                print("🤖 Initializing MLX...")
                try await initializeMLX()
                print("🤖 MLX initialized successfully")
            }
            try await loadRealModel()
            await MainActor.run {
                isModelLoaded = true
                isLoading = false
                print("🤖 MLXLLMManager: Model loaded successfully!")
            }
        } catch {
            print("🤖 MLXLLMManager: Model loading failed: \(error)")
            print("🤖 Error details: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load MLX model: \(error.localizedDescription)"
                isModelLoaded = false
                isLoading = false
            }
        }
    }

    private func initializeMLX() async throws {
        // Set GPU memory limit to prevent out of memory issues
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        isInitialized = true
    }

    private func loadRealModel() async throws {
        // Load the selected model using MLX LLM factory
        let factory = LLMModelFactory.shared
        let model = selectedModel
        
        print("🤖 Loading MLX model: \(model.name)")
        
        // Load model from hub with progress tracking
        let hub = HubApi()
        modelContainer = try await factory.loadContainer(
            hub: hub, 
            configuration: model.configuration
        ) { progress in
            Task { @MainActor in
                // Update progress if needed
                print("🤖 Model download progress: \(progress.fractionCompleted * 100)%")
            }
        }
        
        print("🤖 MLX model loaded successfully: \(model.name)")
    }

    /// Generate a response using MLX local AI
    func generateResponse(for userMessage: String, context: String = "") async -> String {
        guard isModelLoaded, let modelContainer = modelContainer else {
            return "MLX model not loaded yet. Please wait..."
        }

        await saveMessage(userMessage, isUser: true)

        await MainActor.run {
            isLoading = true
        }

        do {
            let response = try await generateRealMLXResponse(for: userMessage, context: context, modelContainer: modelContainer)
        await saveMessage(response, isUser: false)
        await MainActor.run {
            isLoading = false
        }
        return response
        } catch {
            await MainActor.run {
                errorMessage = "Generation failed: \(error.localizedDescription)"
                isLoading = false
            }
            let fallbackResponse = "I'm here to support you on your wellness journey. How can I help you today?"
            await saveMessage(fallbackResponse, isUser: false)
            return fallbackResponse
        }
    }

    // MARK: - Real MLX Text Generation

    private func generateRealMLXResponse(for userMessage: String, context: String, modelContainer: MLXLMCommon.ModelContainer) async throws -> String {
        // Create coaching-specific system prompt
        let systemPrompt = createCoachingSystemPrompt(context: context)
        
        // Convert to MLX chat messages
        let messages = [
            Chat.Message(role: .system, content: systemPrompt),
            Chat.Message(role: .user, content: userMessage)
        ]
        
        // Prepare input for model processing
        let userInput = UserInput(chat: messages)
        
        // Generate response using the real MLX model
        return try await modelContainer.perform { (context: MLXLMCommon.ModelContext) in
            let lmInput = try await context.processor.prepare(input: userInput)
            let parameters = GenerateParameters(
                maxTokens: maxTokens,
                temperature: Float(temperature)
            )
            
            var fullResponse = ""
            let stream = try MLXLMCommon.generate(
                input: lmInput, 
                parameters: parameters, 
                context: context
            )
            
            // Collect the generated response
            for await generation in stream {
                switch generation {
                case .chunk(let chunk):
                    fullResponse += chunk
                case .info(let info):
                    print("Generation info: \(info)")
                case .toolCall(let call):
                    print("Tool call: \(call)")
                }
            }
            
            return fullResponse.isEmpty ? "I'm here to support you on your wellness journey. How can I help you today?" : fullResponse
        }
    }
    
    // private func createCoachingSystemPrompt(context: String) -> String {
    //     return """
    //     You are a compassionate health and wellness coach, helping users build sustainable healthy habits.
        
    //     Core style: Warm, empathetic, non-judgmental; keep responses under 120 words unless requested; encourage reflection; never give medical advice.
        
    //     Response framework:
    //     1. **Venting/struggles:** First: Validate, normalize setbacks, ask if they want to share more or try solutions. Follow-ups: Reference prior input if available, offer a positive perspective if suitable, suggest one idea if relevant.
    //     2. **Factual/nutrition questions:** Answer clearly and simply using general knowledge; include one practical tip if relevant.
    //     3. **Regret over eating:** Normalize, reassure one choice doesn't define them, suggest one step (e.g., hydration) if suitable.
    //     4. **Successes:** Celebrate progress, encourage continuation.
    //     5. **Vague queries:** Ask an open-ended question, offer one idea if suitable.
        
    //     For follow-ups: Reference prior input if available; if not, treat as first response. Tailor to user preferences if mentioned.
        
    //     Provide guidance only if relevant, conversationally unless step-by-step is requested.
        
    //     Context about the user's journey: \(context)
    //     """
    // }

// private func createCoachingSystemPrompt(context: String) -> String {
//     return """
//     You are a compassionate health and wellness coach, helping users build sustainable habits.

//     Goal: Guide users empathetically toward reflection and positive steps, without medical advice. Avoid assumptions about their lifestyle—base suggestions only on what they've shared.

//     Instructions: Keep responses under 120 words unless requested. Be warm, non-judgmental, and concise. Reference prior input or user preferences if available; do not repeat instructions or irrelevant details. For vague queries, start with empathy and one open-ended question before any idea.

//     Tailor to query type:
//     - Venting/struggles/regret: Validate feelings, normalize setbacks, reassure one choice doesn't define them. Ask if they want to share more; suggest at most one small step (e.g., hydration) if it fits naturally.
//     - Factual/nutrition: Answer simply with general knowledge; add one practical tip.
//     - Successes: Celebrate briefly and encourage next steps.
//     - Vague: Empathize, ask one open-ended question (e.g., "What's one thing on your mind?"); offer one gentle idea only if it flows conversationally.

//     User's journey context: \(context)
//     """
// }


private func createCoachingSystemPrompt(context: String) -> String {
    return """
    You are a compassionate health and wellness coach, helping users build sustainable habits.

    Goal: Guide users empathetically toward reflection and positive steps, without medical advice. Avoid assumptions about their lifestyle—base suggestions only on what they've shared.

    Instructions: Keep responses under 120 words unless requested. Be warm, non-judgmental, and concise. Reference prior input or user preferences if available; do not repeat instructions or irrelevant details. For vague queries, start with empathy and one open-ended question before any idea.

    User's journey context: \(context)
    """
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
            return "Loading MLX model..."
        } else if isModelLoaded {
            return "MLX Local AI Ready (\(selectedModel.name))"
        } else {
            return errorMessage ?? "MLX Local AI not loaded"
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
            isInitialized = false
            modelContainer = nil
        }
    }

    // MARK: - Testing Utilities

    /// Get current token usage for testing (rough estimate for display)
    func getCurrentTokenUsage() -> Int {
        let totalText = chatHistory.map { $0.content }.joined()
        return totalText.count / 4 // Rough token estimation
    }
}