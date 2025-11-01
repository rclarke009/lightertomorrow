import Foundation
import SwiftUI
import SwiftData

/// Hybrid LLM Manager that can switch between local and cloud AI
@MainActor
class HybridLLMManager: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoading = false
    @Published var isGeneratingResponse = false
    @Published var errorMessage: String?
    @Published var chatHistory: [LLMMessage] = []
    @Published var isUsingCloudAI = false
    @AppStorage("useCloudAI") private var useCloudAI = false
    @Published var currentConversationId: UUID
    
    // Managers
    private let localManager = MLXLLMManager()
    private let cloudManager = BackendLLMManager()
    
    // Configuration
    private let maxTokens = 2000
    
    init() {
        chatHistory = []
        currentConversationId = UUID() // Initialize with first conversation ID
        // Force cloud AI if coaching feature is enabled (local AI is disabled)
        if FeatureFlags.enableCoaching {
            useCloudAI = true
            isUsingCloudAI = true
        } else {
            isUsingCloudAI = useCloudAI
        }
    }
    
    // MARK: - Model Management
    
    /// Load the appropriate AI model based on user preference
    func loadModel() async {
        print("🔄 HybridLLMManager: Starting model loading...")
        await MainActor.run {
            errorMessage = nil
            // Reset loading state when switching modes
            isModelLoaded = false
        }
        
        if self.isUsingCloudAI {
            print("🔄 HybridLLMManager: Loading ONLINE AI mode...")
            print("🔄 HybridLLMManager: Checking cloud AI connectivity...")
            // No loading state for online AI - just check connectivity
            await self.cloudManager.loadModel()
            await MainActor.run {
                self.isModelLoaded = self.cloudManager.isModelLoaded
                self.errorMessage = self.cloudManager.errorMessage
                print("🔄 HybridLLMManager: Cloud AI ready - isModelLoaded: \(self.isModelLoaded)")
            }
        } else {
            print("🔄 HybridLLMManager: Loading LOCAL AI mode...")
            await MainActor.run {
                self.isLoading = true
                print("🔄 HybridLLMManager: isLoading set to true for local AI")
            }
            
            // Add timeout handling for local AI model loading
            await withTimeout(seconds: 30) {
                await self.localManager.loadModel()
                await MainActor.run {
                    self.isModelLoaded = self.localManager.isModelLoaded
                    self.errorMessage = self.localManager.errorMessage
                    print("🔄 HybridLLMManager: Local AI loaded - isModelLoaded: \(self.isModelLoaded)")
                }
            }
            
            await MainActor.run {
                self.isLoading = false
                print("🔄 HybridLLMManager: isLoading set to false, isModelLoaded: \(self.isModelLoaded)")
            }
        }
    }
    
    /// Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            return await group.first { $0 != nil } ?? nil
        }
    }
    
    /// Generate a response using the appropriate AI
    func generateResponse(for userMessage: String, context: String = "", modelContext: ModelContext? = nil) async -> String {
        // Build context if not provided and ModelContext is available
        let finalContext: String
        if context.isEmpty, let modelContext = modelContext {
            finalContext = buildFullContext(modelContext: modelContext)
            if !finalContext.isEmpty {
                print("📝 DEBUG: Built context (\(finalContext.count) chars): \(finalContext.prefix(200))...")
            }
        } else {
            finalContext = context
        }
        guard isModelLoaded else {
            return "AI model not loaded yet. Please wait..."
        }
        
        // For cloud AI, check usage limit (local AI doesn't track usage)
        if isUsingCloudAI {
            let usageTracker = UsageTracker.shared
            guard await usageTracker.canMakeRequest() else {
                let renewalDate = await usageTracker.getRenewalDateString()
                return "You've reached your monthly token limit (100,000 tokens). Your usage will reset on \(renewalDate). Please try again after the reset."
            }
        }
        
        await MainActor.run {
            isGeneratingResponse = true
        }
        
        let response: String
        
        if isUsingCloudAI {
            response = await cloudManager.generateResponse(for: userMessage, context: finalContext)
            
            // Check if we should show usage warning (only for cloud AI)
            let usageTracker = UsageTracker.shared
            if await usageTracker.shouldShowWarning() {
                await MainActor.run {
                    // Post notification to show warning
                    NotificationCenter.default.post(name: NSNotification.Name("ShowUsageWarning"), object: nil)
                }
                await usageTracker.markWarningShown()
            }
        } else {
            response = await localManager.generateResponse(for: userMessage, context: finalContext)
        }
        
        // Save the message to our chat history (both in-memory and SwiftData)
        await saveMessage(userMessage, isUser: true, modelContext: modelContext)
        await saveMessage(response, isUser: false, modelContext: modelContext)
        
        await MainActor.run {
            isGeneratingResponse = false
        }
        
        return response
    }
    
    // MARK: - AI Mode Switching
    
    /// Switch to local AI mode
    func switchToLocalAI() async {
        await MainActor.run {
            isUsingCloudAI = false
            useCloudAI = false
            // Clear chat history when switching modes for privacy
            chatHistory.removeAll()
        }
        await loadModel()
    }
    
    /// Switch to cloud AI mode
    func switchToCloudAI() async {
        await MainActor.run {
            isUsingCloudAI = true
            useCloudAI = true
            // Clear chat history when switching modes for privacy
            chatHistory.removeAll()
        }
        await loadModel()
    }
    
    /// Update AI mode based on user preference change
    func updateAIMode() async {
        await MainActor.run {
            isUsingCloudAI = useCloudAI
            // Clear chat history when switching modes for privacy
            chatHistory.removeAll()
        }
        await loadModel()
    }
    
    // MARK: - Message Management
    
    /// Save message to both in-memory chatHistory and SwiftData for persistence
    private func saveMessage(_ content: String, isUser: Bool, modelContext: ModelContext? = nil) async {
        await MainActor.run {
            let role: Role = isUser ? .user : .assistant
            let message = LLMMessage(
                role: role,
                content: content,
                timestamp: Date(),
                conversationId: currentConversationId
            )
            chatHistory.append(message)
            
            // Save to SwiftData if ModelContext is available
            if let modelContext = modelContext {
                modelContext.insert(message)
                do {
                    try modelContext.save()
                    print("✅ DEBUG: Saved LLMMessage to SwiftData: \(role.rawValue) - \(content.prefix(50))...")
                    print("✅ DEBUG: Message timestamp: \(message.timestamp)")
                    print("✅ DEBUG: Message ID: \(message.id)")
                    print("✅ DEBUG: Conversation ID: \(message.conversationId)")
                } catch {
                    print("❌ DEBUG: Failed to save LLMMessage to SwiftData: \(error)")
                    print("❌ DEBUG: Error details: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ DEBUG: No ModelContext provided to saveMessage - message not saved to SwiftData")
            }
        }
    }
    
    /// Load chat history from SwiftData
    func loadChatHistory(modelContext: ModelContext?) async {
        guard let modelContext = modelContext else {
            print("⚠️ DEBUG: No ModelContext provided, skipping chat history load")
            return
        }
        
        await MainActor.run {
            let descriptor = FetchDescriptor<LLMMessage>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            do {
                let messages = try modelContext.fetch(descriptor)
                chatHistory = messages
                // Set currentConversationId to the most recent conversation's ID
                // This allows new messages to continue the most recent conversation unless "New Conversation" is clicked
                if let mostRecentMessage = messages.last {
                    currentConversationId = mostRecentMessage.conversationId
                    print("✅ DEBUG: Loaded \(messages.count) messages from SwiftData")
                    print("✅ DEBUG: Set currentConversationId to most recent: \(currentConversationId)")
                } else {
                    // No messages, keep the new conversation ID that was initialized
                    print("✅ DEBUG: No existing messages, keeping new conversation ID: \(currentConversationId)")
                }
            } catch {
                print("❌ DEBUG: Failed to load chat history from SwiftData: \(error)")
                chatHistory = []
            }
        }
    }
    
    /// Clear current conversation (in-memory only, preserves SwiftData history) and start a new conversation with a new ID
    func startNewConversation() {
        chatHistory = []
        currentConversationId = UUID() // Generate new conversation ID
        print("✅ Started new conversation - chat history cleared, new conversation ID: \(currentConversationId)")
    }
    
    /// Load conversation containing a specific message (loads messages from the same day)
    func loadConversation(containing messageTimestamp: Date, modelContext: ModelContext?) async {
        guard let modelContext = modelContext else {
            print("⚠️ DEBUG: No ModelContext provided, skipping conversation load")
            return
        }
        
        await MainActor.run {
            let calendar = Calendar.current
            let messageDay = calendar.startOfDay(for: messageTimestamp)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: messageDay)!
            
            print("🔍 DEBUG: Loading conversation for timestamp: \(messageTimestamp)")
            print("🔍 DEBUG: Message day: \(messageDay)")
            print("🔍 DEBUG: Next day: \(nextDay)")
            
            let descriptor = FetchDescriptor<LLMMessage>(
                predicate: #Predicate<LLMMessage> { message in
                    message.timestamp >= messageDay && message.timestamp < nextDay
                },
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            do {
                let messages = try modelContext.fetch(descriptor)
                chatHistory = messages
                // Update currentConversationId to match the loaded conversation
                if let firstMessage = messages.first {
                    currentConversationId = firstMessage.conversationId
                    print("✅ DEBUG: Loaded conversation with \(messages.count) messages from \(messageDay)")
                    print("✅ DEBUG: Set currentConversationId to: \(currentConversationId)")
                }
            } catch {
                print("❌ DEBUG: Failed to load conversation from SwiftData: \(error)")
                // Fallback: load all messages
                Task {
                    await loadChatHistory(modelContext: modelContext)
                }
            }
        }
    }
    
    /// Load conversation within a specific time range
    func loadConversation(from startTime: Date, to endTime: Date, modelContext: ModelContext?) async {
        guard let modelContext = modelContext else {
            print("⚠️ DEBUG: No ModelContext provided, skipping conversation load")
            return
        }
        
        await MainActor.run {
            // Add small buffer to ensure we get all messages in the conversation
            let buffer: TimeInterval = 1 // 1 second buffer
            
            let startTimeWithBuffer = startTime.addingTimeInterval(-buffer)
            let endTimeWithBuffer = endTime.addingTimeInterval(buffer)
            
            print("🔍 DEBUG: Loading conversation from \(startTime) to \(endTime)")
            
            let descriptor = FetchDescriptor<LLMMessage>(
                predicate: #Predicate<LLMMessage> { message in
                    message.timestamp >= startTimeWithBuffer && message.timestamp <= endTimeWithBuffer
                },
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            do {
                let messages = try modelContext.fetch(descriptor)
                chatHistory = messages
                // Update currentConversationId to match the loaded conversation
                if let firstMessage = messages.first {
                    currentConversationId = firstMessage.conversationId
                    print("✅ DEBUG: Loaded conversation with \(messages.count) messages from time range")
                    print("✅ DEBUG: Set currentConversationId to: \(currentConversationId)")
                }
            } catch {
                print("❌ DEBUG: Failed to load conversation from SwiftData: \(error)")
                // Fallback: load all messages
                Task {
                    await loadChatHistory(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - Model Status
    
    var modelStatus: String {
        if isLoading {
            return "Loading AI model..."
        } else if isModelLoaded {
            if isUsingCloudAI {
                return "Enhanced Cloud AI Ready (2000 token limit)"
            } else {
                return "Local AI Ready (Private & Offline)"
            }
        } else {
            return "AI model not loaded"
        }
    }
    
    var currentModeDescription: String {
        if isUsingCloudAI {
            return "Enhanced Cloud Coach\nRicher conversations, requires internet"
        } else {
            return "Local Coach\nFast, private, offline"
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        localManager.clearError()
        cloudManager.clearError()
    }
    
    // MARK: - Cleanup
    
    func unloadModel() async {
        await MainActor.run {
            isModelLoaded = false
            chatHistory.removeAll()
        }
        await localManager.unloadModel()
        await cloudManager.unloadModel()
    }
    
    // MARK: - Context Building
    
    /// Build conversation history context from chatHistory array
    private func buildConversationContext() -> String {
        guard !chatHistory.isEmpty else {
            return ""
        }
        
        // Include last 10 messages (5 user + 5 assistant pairs)
        let recentMessages = Array(chatHistory.suffix(10))
        
        var contextLines: [String] = []
        for message in recentMessages {
            let roleLabel = message.role == .user ? "[User]" : "[Assistant]"
            contextLines.append("\(roleLabel): \(message.content)")
        }
        
        if !contextLines.isEmpty {
            return "Previous conversation:\n" + contextLines.joined(separator: "\n")
        }
        
        return ""
    }
    
    /// Build app entry context from SwiftData (positive/neutral only)
    private func buildAppEntryContext(modelContext: ModelContext) -> String {
        var contextParts: [String] = []
        
        // Check if sharing app data is enabled (default to true for now)
        let shareAppData = UserDefaults.standard.object(forKey: "shareAppDataWithCoach") as? Bool ?? true
        guard shareAppData else {
            return ""
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Get today's DailyEntry for morning focus
        // Use date range comparison instead of isDate (not supported in #Predicate)
        let todayDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= today && entry.date < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let todayEntry = try? modelContext.fetch(todayDescriptor).first {
            // Include positive/neutral morning focus data
            if !todayEntry.whyThisMatters.isEmpty {
                contextParts.append("- Today's 'why this matters': \(todayEntry.whyThisMatters)")
            }
            if let identity = todayEntry.identityStatement, !identity.isEmpty {
                contextParts.append("- Identity statement: \(identity)")
            }
            if !todayEntry.todaysFocus.isEmpty {
                contextParts.append("- Today's focus: \(todayEntry.todaysFocus)")
            }
            if !todayEntry.stressResponse.isEmpty {
                contextParts.append("- Stress response plan: \(todayEntry.stressResponse)")
            }
        }
        
        // Get recent success notes (last 5, positive only)
        let successDescriptor = FetchDescriptor<SuccessNote>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let successNotes = try? modelContext.fetch(successDescriptor).prefix(5), !successNotes.isEmpty {
            let successTexts = successNotes.map { $0.text }
            contextParts.append("- Recent successes: " + successTexts.joined(separator: "; "))
        }
        
        // Get streak information (positive pattern)
        let streakManager = StreakManager()
        let streak = streakManager.streak
        if streak > 0 {
            contextParts.append("- Current streak: \(streak) days")
        }
        
        // Count total days using app (entries count)
        let allEntriesDescriptor = FetchDescriptor<DailyEntry>()
        if let allEntries = try? modelContext.fetch(allEntriesDescriptor) {
            let daysUsingApp = Set(allEntries.map { calendar.startOfDay(for: $0.date) }).count
            if daysUsingApp > 0 {
                contextParts.append("- Using the app for \(daysUsingApp) days")
            }
        }
        
        if contextParts.isEmpty {
            return ""
        }
        
        return "User's recent journey:\n" + contextParts.joined(separator: "\n")
    }
    
    /// Build full context combining conversation history and app entry data
    func buildFullContext(modelContext: ModelContext?) -> String {
        var contextParts: [String] = []
        
        // Always include conversation history
        let conversationContext = buildConversationContext()
        if !conversationContext.isEmpty {
            contextParts.append(conversationContext)
        }
        
        // Conditionally include app entry context if ModelContext is available
        if let modelContext = modelContext {
            let appContext = buildAppEntryContext(modelContext: modelContext)
            if !appContext.isEmpty {
                contextParts.append(appContext)
            }
        }
        
        return contextParts.joined(separator: "\n\n")
    }
    
    // MARK: - Testing Utilities
    
    /// Get current token usage for testing (rough estimate for display)
    func getCurrentTokenUsage() -> Int {
        let totalText = chatHistory.map { $0.content }.joined()
        return totalText.count / 4 // Rough token estimation
    }
}
