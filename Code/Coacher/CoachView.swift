//
//  CoachView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import UIKit

struct CoachView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hybridManager: HybridLLMManager
    @State private var userMessage = ""
    @State private var showConversationHistory = false
    @State private var showOnlineAIConfirmation = false
    @State private var showComingSoon = !FeatureFlags.enableCoaching // Show coming soon overlay unless coaching is enabled
    @State private var showUsageWarning = false
    @State private var scrollToLastMessage = false
    @State private var hasLoadedInitialHistory = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Fixed Top Bar
                    HStack {
                        // Start New Conversation Button (Top Left)
                        Button(action: { 
                            hybridManager.startNewConversation()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("New Chat")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.brandBlue)
                            )
                        }
                        
                        // AI Mode Toggle Button (Top Left) - Hidden until local AI option is available
                        if FeatureFlags.useLocalLLM {
                            Button(action: { 
                                showOnlineAIConfirmation = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: hybridManager.isUsingCloudAI ? "cloud.fill" : "iphone")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text(hybridManager.isUsingCloudAI ? "Online" : "Local")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    if hybridManager.isUsingCloudAI {
                                        Text("• \(hybridManager.getCurrentTokenUsage())")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(hybridManager.isUsingCloudAI ? Color.blue : Color.green)
                                )
                            }
                        }
                        
                        Spacer()
                        
                        // AI Status Indicator (Top Center) - Only show if loading or not ready
                        if hybridManager.isLoading {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading AI...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        } else if !hybridManager.isModelLoaded {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("AI not ready")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // History Button (Top Right)
                        Button(action: { showConversationHistory = true }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.cardBackground)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4) //geometry.safeAreaInsets.top + 0)
                    .padding(.bottom, 8)
                    .background(Color.appBackground)
                    
                    // Chat Messages Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if hybridManager.chatHistory.isEmpty {
                                    // Welcome Message
                                    VStack(spacing: 20) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 60))
                                            .foregroundColor(.brandBlue)
                                        
                                        Text("AI Coach")
                                            .font(.largeTitle)
                                            .bold()
                                            .foregroundColor(.dynamicText)
                                        
                                        if hybridManager.isLoading {
                                            SparkleProgressView(isLoading: true, progressValue: 0.0)
                                        } else if hybridManager.isModelLoaded {
                                            Text("I'm here to help you build healthier habits and achieve your goals. What would you like to work on today?")
                                                .font(.body)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.dynamicSecondaryText)
                                                .padding(.horizontal, 20)
                                        } else {
                                            Text("Preparing your AI coach...")
                                                .font(.body)
                                                .foregroundColor(.helpButtonBlue)
                                        }
                                    }
                                    .padding(.top, 40)
                                } else {
                                    // Chat Messages
                                    ForEach(hybridManager.chatHistory) { message in
                                        ChatBubble(message: message)
                                            .id(message.id)
                                    }
                                }
                                
                                if hybridManager.isGeneratingResponse {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .id("generating")
                                }
                            }
                            .padding()
                        }
                        .onTapGesture {
                            // Dismiss keyboard when tapping on chat area
                            hideKeyboard()
                        }
                        .onChange(of: hybridManager.chatHistory.count) { _, _ in
                            // Auto-scroll to show the latest message when new messages are added
                            if let lastMessage = hybridManager.chatHistory.last {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .top)
                                }
                            }
                        }
                        .onChange(of: scrollToLastMessage) { _, shouldScroll in
                            // Scroll to last (most recent) message when loading conversation from history
                            print("🔄 DEBUG: onChange scrollToLastMessage triggered, shouldScroll: \(shouldScroll), chatHistory.count: \(hybridManager.chatHistory.count)")
                            if shouldScroll, let lastMessage = hybridManager.chatHistory.last {
                                print("✅ DEBUG: Scrolling to last message with id: \(lastMessage.id)")
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                                // Reset flag after a brief delay to avoid immediate re-triggering
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    scrollToLastMessage = false
                                }
                            }
                        }
                    }
                    
                    // Message Input
                    VStack(spacing: 12) {
                        // Model Loading State - Simple indicator in input area
                        if hybridManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading AI model...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.cardBackground.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Input Field (disabled when model not ready)
                        HStack(spacing: 12) {
                            CustomTextField(
                                placeholder: hybridManager.isModelLoaded ? "Ask your AI coach..." : "AI model loading...",
                                text: $userMessage,
                                isEnabled: hybridManager.isModelLoaded && !hybridManager.isLoading,
                                colorScheme: colorScheme
                            )
                            .frame(height: 36)
                            .frame(maxWidth: .infinity) // Allow text field to take available space
                            .layoutPriority(1) // Give text field priority in layout
                            .opacity(hybridManager.isModelLoaded ? 1.0 : 0.6)
                            .onSubmit {
                                if hybridManager.isModelLoaded && !hybridManager.isLoading {
                                    sendMessage()
                                }
                            }
                            .onTapGesture {
                                // Don't dismiss keyboard when tapping text field
                            }
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(hybridManager.isModelLoaded ? Color.brandBlue : Color.gray)
                                .clipShape(Circle())
                            }
                            .disabled(
                                userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                                hybridManager.isGeneratingResponse || 
                                !hybridManager.isModelLoaded || 
                                hybridManager.isLoading
                            )
                            .fixedSize() // Prevent button from shrinking
                        }
                        .padding(.horizontal, 4)
                        .fixedSize(horizontal: false, vertical: true) // Prevent horizontal overflow
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .onTapGesture {
                        // Don't dismiss keyboard when tapping input area
                    }
                }
                .background(
                    Color.appBackground
                        .ignoresSafeArea(.all)
                )
            }
            
            // Coming Soon Overlay
            if showComingSoon {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showComingSoon = false
                    }
                
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AI Coach")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Text("Coming Soon")
                    //     .font(.title2)
                    //     .fontWeight(.medium)
                    //     .foregroundColor(.secondary)
                    
                    Text("Your AI coach is being prepared to help you on your wellness journey. Stay tuned!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Got it") {
                        showComingSoon = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.top, 10)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showConversationHistory) {
            ConversationHistoryView()
                .environmentObject(hybridManager)
        }
        .sheet(isPresented: $showOnlineAIConfirmation) {
            OnlineAIConfirmationView()
                .environmentObject(hybridManager)
        }
        .sheet(isPresented: $showUsageWarning) {
            UsageWarningView()
        }
        .onAppear {
            // Model loading is now handled globally in CoacherApp
            // No need to load here as it's already started in background
            
            // Load chat history from SwiftData when view appears (only first time)
            if !hasLoadedInitialHistory {
                Task {
                    await hybridManager.loadChatHistory(modelContext: modelContext)
                    hasLoadedInitialHistory = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowUsageWarning"))) { _ in
            showUsageWarning = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoadConversation"))) { notification in
            if let userInfo = notification.userInfo {
                // Try new format first (with startTime and endTime)
                if let startTime = userInfo["startTime"] as? Date,
                   let endTime = userInfo["endTime"] as? Date {
                    print("🔔 DEBUG: Received LoadConversation notification with time range: \(startTime) to \(endTime)")
                    Task {
                        await hybridManager.loadConversation(from: startTime, to: endTime, modelContext: modelContext)
                        // Set flag to scroll to last (most recent) message after loading
                        print("✅ DEBUG: Setting scrollToLastMessage to true")
                        scrollToLastMessage = true
                    }
                }
                // Fallback to old format (with timestamp) for backward compatibility
                else if let timestamp = userInfo["timestamp"] as? Date {
                    print("🔔 DEBUG: Received LoadConversation notification with timestamp: \(timestamp)")
                    Task {
                        await hybridManager.loadConversation(containing: timestamp, modelContext: modelContext)
                        // Set flag to scroll to last (most recent) message after loading
                        print("✅ DEBUG: Setting scrollToLastMessage to true")
                        scrollToLastMessage = true
                    }
                }
            }
        }
        .onChange(of: hybridManager.isUsingCloudAI) { _, _ in
            Task {
                await hybridManager.updateAIMode()
            }
        }
    }
    
    // MARK: - Message Handling
    
    private func sendMessage() {
        let message = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        userMessage = ""
        hideKeyboard() // Dismiss keyboard when sending
        
        // Auto-scroll will be handled by the ScrollViewReader in the view
        
        Task {
            _ = await hybridManager.generateResponse(for: message, modelContext: modelContext)
        }
    }
    
    // MARK: - Keyboard Management
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Scroll Position Detection
    
    // Scroll position is now detected using onScrollGeometryChange
    // which provides accurate scroll offset information
}

struct FeaturePreviewRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.brandBlue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.dynamicText)
            
            Spacer()
        }
    }
}

// MARK: - Chat Bubble Component

struct ChatBubble: View {
    let message: LLMMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.brandBlue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.cardBackground)
                        .foregroundColor(Color(UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
                        }))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Custom TextField with Placeholder Color Control

struct CustomTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let isEnabled: Bool
    let colorScheme: ColorScheme
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.returnKeyType = .default
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        
        // Configure text field to handle long text properly
        textField.adjustsFontSizeToFitWidth = false
        textField.contentHorizontalAlignment = .left
        textField.contentVerticalAlignment = .center
        
        // Set compression resistance to prevent layout issues
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        updatePlaceholderColor(textField)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isEnabled = isEnabled
        uiView.textColor = colorScheme == .dark ? .white : .label
        uiView.placeholder = placeholder
        updatePlaceholderColor(uiView)
    }
    
    private func updatePlaceholderColor(_ textField: UITextField) {
        let placeholderColor: UIColor = colorScheme == .dark ? .white : .placeholderText
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

#Preview {
    CoachView()
}