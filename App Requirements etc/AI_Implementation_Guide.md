# AI Coach Implementation Guide
## Weight Loss Coach iOS App

This guide provides comprehensive instructions for implementing the hybrid AI approach in the Coacher app, supporting both online (GPT-4o) and private (Apple Foundation Models) AI modes.

## Overview

The Coacher app uses a hybrid AI approach to provide flexible, privacy-conscious coaching:

- **Online Mode (GPT-4o):** Advanced reasoning, multimodal support, real-time responses
- **Private Mode (Apple Foundation Models):** Complete privacy, offline capability, on-device processing

## Architecture

```
HybridLLMManager (Coordinator)
├── OnlineCoachingService (GPT-4o)
│   ├── OpenAI API Integration
│   ├── Multimodal Support
│   └── Advanced Reasoning
└── PrivateCoachingService (Apple Foundation Models)
    ├── FoundationModels Framework
    ├── Neural Engine Processing
    └── Complete Privacy
```

## Implementation Options

### Option 1: Online Mode (GPT-4o via OpenAI API)

**Strengths:**
- Advanced reasoning for complex coaching scenarios
- Multimodal support (text + images for meal analysis)
- Real-time responses (1-2 second latency)
- Sophisticated conversation handling

**Use Cases:**
- Complex emotional support conversations
- Meal analysis via photo uploads
- Deep habit analysis and CBT techniques
- Advanced nutrition guidance

**Requirements:**
- Internet connection
- OpenAI API key
- User consent for data sharing

#### Setup Steps

1. **Add OpenAI Package Dependency**
   ```swift
   // In Xcode: File > Add Package Dependencies
   // URL: https://github.com/MacPaw/OpenAI
   ```

2. **API Key Management**
   ```swift
   import KeychainAccess
   
   class KeychainManager {
       static let shared = KeychainManager()
       private let keychain = Keychain(service: "com.coacher.openai")
       
       func setOpenAIKey(_ key: String) {
           keychain["openai_api_key"] = key
       }
       
       func getOpenAIKey() -> String? {
           return keychain["openai_api_key"]
       }
   }
   ```

3. **Service Implementation**
   ```swift
   import OpenAI
   import SwiftUI
   
   class OnlineCoachingService: ObservableObject, LLMService {
       var isOnlineMode: Bool = true
       private let openAI: OpenAI.Client
       
       init() {
           guard let apiKey = KeychainManager.shared.getOpenAIKey() else {
               fatalError("OpenAI API key not found")
           }
           openAI = OpenAI.Client(apiToken: apiKey)
       }
       
       func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
           let systemPrompt = createSystemPrompt(context: context)
           
           let chatMessages: [ChatMessage] = [
               ChatMessage.role(.system, content: .string(systemPrompt))
           ] + messages.map { message in
               ChatMessage.role(
                   message.role == .user ? .user : .assistant,
                   content: .string(message.content)
               )
           }
           
           let query = ChatQuery(
               model: .gpt4_o,
               messages: chatMessages,
               maxTokens: 400,
               temperature: 0.7
           )
           
           let result = try await openAI.chats(query: query)
           return result.choices.first?.message.content ?? "Sorry, please try again."
       }
       
       private func createSystemPrompt(context: CoachContext) -> String {
           return """
           You are a compassionate, pragmatic weight-loss coach. Focus on sustainable healthy decisions, addressing mental health triggers (anxiety-driven snacking) and bad habits using CBT-inspired techniques. Include basic nutrition guidance but prioritize mindset and emotional support.
           
           User Context:
           - Today's Why: \(context.todayWhy)
           - Chosen Swap: \(context.todaySwap)
           - Commitment: \(context.commitTo) instead of \(context.commitFrom)
           - Current Streak: \(context.currentStreak) days
           
           Guidelines:
           - Use the user's daily context in responses
           - Avoid shame or judgment
           - Offer one concrete next step
           - Keep replies under 200 words unless asked
           - End with an engaging question
           - Include disclaimer: "This isn't medical advice—consult professionals for mental health/nutrition"
           """
       }
   }
   ```

### Option 2: Private Mode (Apple Foundation Models)

**Strengths:**
- Complete privacy - no data leaves device
- Offline capability
- No API costs
- Optimized for iPhone 15 Pro+ Neural Engine

**Use Cases:**
- Daily check-ins and habit reminders
- Basic coaching conversations
- Privacy-sensitive discussions
- Offline coaching support

**Requirements:**
- iOS 18+
- iPhone 15 Pro+ (for optimal performance)
- FoundationModels framework

#### Setup Steps

1. **Framework Import**
   ```swift
   import FoundationModels
   import CoreML
   ```

2. **Service Implementation**
   ```swift
   class PrivateCoachingService: ObservableObject, LLMService {
       var isOnlineMode: Bool = false
       private let model: LanguageModel
       
       init() {
           do {
               model = try LanguageModel.default
           } catch {
               fatalError("Failed to load Foundation Model: \(error)")
           }
       }
       
       func generateReply(to messages: [LLMMessage], context: CoachContext) async throws -> String {
           let systemPrompt = createSystemPrompt(context: context)
           let conversation = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
           
           let prompt = """
           \(systemPrompt)
           
           Conversation:
           \(conversation)
           
           Coach:
           """
           
           let session = model.startSession()
           let request = GenerateTextRequest(
               prompt: prompt,
               options: GenerateTextOptions(
                   maxTokens: 300,
                   temperature: 0.7,
                   topP: 0.9
               )
           )
           
           let response = try await session.generateText(request)
           return response.content.text ?? "Sorry, please try again."
       }
       
       private func createSystemPrompt(context: CoachContext) -> String {
           return """
           You are a compassionate, pragmatic weight-loss coach. Focus on sustainable healthy decisions, addressing mental health triggers and bad habits using CBT-inspired techniques. Include basic nutrition guidance but prioritize mindset and emotional support.
           
           User Context:
           - Today's Why: \(context.todayWhy)
           - Chosen Swap: \(context.todaySwap)
           - Commitment: \(context.commitTo) instead of \(context.commitFrom)
           - Current Streak: \(context.currentStreak) days
           
           Guidelines:
           - Use the user's daily context in responses
           - Avoid shame or judgment
           - Offer one concrete next step
           - Keep replies under 200 words unless asked
           - End with an engaging question
           - Include disclaimer: "This isn't medical advice—consult professionals for mental health/nutrition"
           """
       }
   }
   ```

### Option 3: Hybrid Manager

The hybrid manager coordinates both services and provides seamless switching:

```swift
class HybridLLMManager: ObservableObject {
    @Published var isOnlineMode: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var chatHistory: [LLMMessage] = []
    
    @AppStorage("preferOnlineAI") private var preferOnlineAI = false
    
    private let onlineService = OnlineCoachingService()
    private let privateService = PrivateCoachingService()
    
    var currentService: LLMService {
        isOnlineMode ? onlineService : privateService
    }
    
    init() {
        isOnlineMode = preferOnlineAI
    }
    
    func loadModel() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if isOnlineMode {
                // Online mode is always "ready" if API key exists
                await MainActor.run {
                    isModelLoaded = KeychainManager.shared.getOpenAIKey() != nil
                    if !isModelLoaded {
                        errorMessage = "OpenAI API key not found. Please add your API key in Settings."
                    }
                }
            } else {
                // Private mode needs to initialize the model
                _ = try await privateService.generateReply(
                    to: [LLMMessage(role: .system, content: "Test")],
                    context: CoachContext(todayWhy: "", todaySwap: "", commitTo: "", commitFrom: "")
                )
                await MainActor.run {
                    isModelLoaded = true
                }
            }
        } catch {
            await MainActor.run {
                isModelLoaded = false
                errorMessage = "Failed to load AI model: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func generateResponse(for userMessage: String, context: CoachContext) async -> String {
        guard isModelLoaded else {
            return "AI model not loaded yet. Please wait..."
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let response = try await currentService.generateReply(
                to: chatHistory + [LLMMessage(role: .user, content: userMessage)],
                context: context
            )
            
            await MainActor.run {
                chatHistory.append(LLMMessage(role: .user, content: userMessage))
                chatHistory.append(LLMMessage(role: .assistant, content: response))
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            return response
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to generate response: \(error.localizedDescription)"
            }
            return "Sorry, I encountered an error. Please try again."
        }
    }
    
    func switchMode() async {
        await MainActor.run {
            isOnlineMode.toggle()
            preferOnlineAI = isOnlineMode
            // Clear chat history when switching modes for privacy
            chatHistory.removeAll()
        }
        await loadModel()
    }
}
```

## SwiftUI Integration

### Chat View Implementation

```swift
struct CoachView: View {
    @StateObject private var aiManager = HybridLLMManager()
    @State private var messageText = ""
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                // AI Mode Indicator
                HStack {
                    Image(systemName: aiManager.isOnlineMode ? "cloud" : "lock.shield")
                        .foregroundColor(aiManager.isOnlineMode ? .blue : .green)
                    Text(aiManager.isOnlineMode ? "Enhanced AI (Online)" : "Private AI (Offline)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Switch") {
                        Task {
                            await aiManager.switchMode()
                        }
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                
                // Chat Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(aiManager.chatHistory) { message in
                            MessageBubble(message: message)
                        }
                        
                        if aiManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                
                // Message Input
                HStack {
                    TextField("Ask your coach anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.isEmpty || aiManager.isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AISettingsView(aiManager: aiManager)
            }
            .onAppear {
                Task {
                    await aiManager.loadModel()
                }
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = messageText
        messageText = ""
        
        Task {
            let context = CoachContext(
                todayWhy: "Get healthier for my family",
                todaySwap: "Water instead of soda",
                commitTo: "Drink water",
                commitFrom: "Drink soda",
                currentStreak: 3,
                daysThisWeek: 4
            )
            
            _ = await aiManager.generateResponse(for: userMessage, context: context)
        }
    }
}

struct MessageBubble: View {
    let message: LLMMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                Spacer()
            }
        }
    }
}
```

### Settings Integration

```swift
struct AISettingsView: View {
    @ObservedObject var aiManager: HybridLLMManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAPIKeySheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section("AI Mode") {
                    HStack {
                        Image(systemName: aiManager.isOnlineMode ? "cloud" : "lock.shield")
                            .foregroundColor(aiManager.isOnlineMode ? .blue : .green)
                        VStack(alignment: .leading) {
                            Text(aiManager.isOnlineMode ? "Enhanced AI (Online)" : "Private AI (Offline)")
                            Text(aiManager.isOnlineMode ? "Advanced reasoning, requires internet" : "Complete privacy, works offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { aiManager.isOnlineMode },
                            set: { _ in
                                Task {
                                    await aiManager.switchMode()
                                }
                            }
                        ))
                    }
                }
                
                if aiManager.isOnlineMode {
                    Section("OpenAI Configuration") {
                        HStack {
                            Text("API Key")
                            Spacer()
                            if KeychainManager.shared.getOpenAIKey() != nil {
                                Text("Configured")
                                    .foregroundColor(.green)
                            } else {
                                Text("Not Set")
                                    .foregroundColor(.red)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showingAPIKeySheet = true
                        }
                    }
                }
                
                Section("Privacy") {
                    Text("Online Mode: Your conversations are sent to OpenAI for processing. We recommend using Private Mode for sensitive topics.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Private Mode: All processing happens on your device. No data is sent to external servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Model Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        if aiManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if aiManager.isModelLoaded {
                            Text("Ready")
                                .foregroundColor(.green)
                        } else {
                            Text("Not Loaded")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let error = aiManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeySetupView()
            }
        }
    }
}
```

## Privacy and Security Considerations

### Data Handling

1. **Online Mode:**
   - Clear user consent before enabling
   - API keys stored securely in Keychain
   - Chat history cleared when switching modes
   - Transparent data usage policies

2. **Private Mode:**
   - All processing on-device
   - No data transmission
   - Local storage only
   - Complete privacy guarantee

### User Consent Flow

```swift
struct PrivacyConsentView: View {
    @Binding var isPresented: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Enhanced AI Mode")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Online mode uses GPT-4o for advanced coaching conversations. Your messages will be sent to OpenAI for processing.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Advanced reasoning and emotional support")
                Text("• Multimodal support (text + images)")
                Text("• Real-time responses")
                Text("• Data sent to OpenAI servers")
            }
            .font(.caption)
            
            HStack(spacing: 16) {
                Button("Use Private Mode") {
                    onDecline()
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("Enable Enhanced AI") {
                    onAccept()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

## Performance Optimization

### Online Mode
- Implement request caching for common queries
- Use streaming responses for real-time typing effect
- Handle network errors gracefully
- Implement retry logic with exponential backoff

### Private Mode
- Optimize for iPhone 15 Pro+ Neural Engine
- Implement response caching
- Use appropriate model parameters for mobile
- Handle memory constraints gracefully

## Testing Strategy

### Unit Tests
- Test service initialization
- Test mode switching
- Test error handling
- Test context integration

### Integration Tests
- Test full conversation flows
- Test privacy mode switching
- Test offline functionality
- Test API key management

### User Testing
- Test onboarding flow
- Test mode switching UX
- Test conversation quality
- Test performance on target devices

## Deployment Considerations

### App Store Requirements
- Clear privacy policy for online mode
- Accurate description of AI capabilities
- Proper handling of user data
- Compliance with Apple's AI guidelines

### Performance Targets
- Online mode: < 2 second response time
- Private mode: < 5 second response time
- Smooth mode switching
- Minimal battery impact

## Conclusion

This hybrid approach provides the best of both worlds:
- **Privacy-first users** get complete on-device processing
- **Power users** get advanced AI capabilities
- **Seamless switching** between modes based on needs
- **Comprehensive privacy controls** and user consent

The implementation is designed to be maintainable, scalable, and user-friendly while respecting user privacy preferences.
