//
//  ConversationHistoryView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 9/6/25.
//

import SwiftUI
import SwiftData

struct ConversationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hybridManager: HybridLLMManager
    @State private var searchText = ""
    @State private var selectedConversation: ConversationGroup?
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: ConversationGroup?
    @State private var showStorageWarning = false
    @Query(sort: \LLMMessage.timestamp, order: .reverse) private var allMessages: [LLMMessage]
    
    // Storage threshold: 50MB
    private let storageThresholdMB: Double = 50.0
    
    // Estimate storage size (approximately 500 bytes per message)
    private var estimatedStorageMB: Double {
        let bytesPerMessage: Double = 500.0
        let totalBytes = Double(allMessages.count) * bytesPerMessage
        return totalBytes / (1024.0 * 1024.0) // Convert to MB
    }
    
    // Check if storage exceeds threshold
    private var exceedsStorageThreshold: Bool {
        estimatedStorageMB >= storageThresholdMB
    }
    
    // Group conversations by conversationId first, then by date
    private var groupedConversations: [ConversationGroup] {
        print("🔍 DEBUG: Starting conversation grouping")
        print("🔍 DEBUG: Total messages from query: \(allMessages.count)")
        
        let conversations = allMessages
            .filter { message in
                searchText.isEmpty || 
                message.content.localizedCaseInsensitiveContains(searchText)
            }
        
        print("🔍 DEBUG: Messages after search filter: \(conversations.count)")
        
        // First group by conversationId (primary grouping method)
        let groupedByConversationId = Dictionary(grouping: conversations) { message in
            message.conversationId
        }
        
        print("🔍 DEBUG: Messages grouped into \(groupedByConversationId.keys.count) unique conversation IDs")
        
        var allConversationGroups: [ConversationGroup] = []
        
        // Process each conversation group
        for (conversationId, messages) in groupedByConversationId {
            // Sort messages by timestamp within this conversation
            let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
            
            guard !sortedMessages.isEmpty else { continue }
            
            let date = Calendar.current.startOfDay(for: sortedMessages.first!.timestamp)
            let startTime = sortedMessages.first!.timestamp
            let endTime = sortedMessages.last!.timestamp
            
            print("🔍 DEBUG: Conversation ID \(conversationId.uuidString.prefix(8)): \(sortedMessages.count) messages, date=\(date), start=\(startTime), end=\(endTime)")
            
            // Create conversation group (messages sorted newest first for display)
            allConversationGroups.append(ConversationGroup(
                conversationId: conversationId,
                date: date,
                startTime: startTime,
                endTime: endTime,
                messages: sortedMessages.sorted { $0.timestamp > $1.timestamp }
            ))
        }
        
        // Sort by date (newest first), then by start time (newest first) within same day
        let result = allConversationGroups.sorted { group1, group2 in
            if group1.date != group2.date {
                return group1.date > group2.date
            }
            return group1.startTime > group2.startTime
        }
        
        print("🔄 DEBUG: groupedConversations computed - total messages: \(allMessages.count), conversation groups: \(result.count)")
        for (index, group) in result.enumerated() {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            print("🔍 DEBUG: Group \(index + 1): date=\(formatter.string(from: group.date)), start=\(formatter.string(from: group.startTime)), end=\(formatter.string(from: group.endTime)), messages=\(group.messages.count)")
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar with Storage Info
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search conversations...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Storage info
                    HStack {
                        Text("\(groupedConversations.count) \(groupedConversations.count == 1 ? "conversation" : "conversations"), ~\(String(format: "%.1f", estimatedStorageMB)) MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if exceedsStorageThreshold {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Conversation List
                if groupedConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No conversations yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Start chatting with your AI coach to see your conversation history here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedConversations) { group in
                            ConversationRow(group: group)
                                .id(group.id)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        conversationToDelete = group
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture {
                                    print("🔍 DEBUG: Tapped conversation: \(group.startTime)")
                                    // Post notification with conversation time range
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("LoadConversation"),
                                        object: nil,
                                        userInfo: [
                                            "startTime": group.startTime,
                                            "endTime": group.endTime
                                        ]
                                    )
                                    dismiss()
                                }
                                .onAppear {
                                    print("🔍 DEBUG: ConversationRow appeared for group with startTime: \(group.startTime)")
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        print("🔍 DEBUG: List appeared with \(groupedConversations.count) conversation groups")
                    }
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            showDeleteAllConfirmation = true
                        }) {
                            Label("Delete All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Conversation", isPresented: $showDeleteConfirmation, presenting: conversationToDelete) { group in
                Button("Cancel", role: .cancel) {
                    conversationToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let group = conversationToDelete {
                        Task {
                            do {
                                try await hybridManager.deleteConversation(conversationId: group.conversationId, modelContext: modelContext)
                            } catch {
                                print("❌ Failed to delete conversation: \(error)")
                            }
                        }
                    }
                    conversationToDelete = nil
                }
            } message: { group in
                let messageCount = group.messages.count
                Text("Delete this conversation with \(messageCount) \(messageCount == 1 ? "message" : "messages")? This cannot be undone.")
            }
            .alert("Delete All Conversations", isPresented: $showDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    Task {
                        do {
                            try await hybridManager.deleteAllConversations(modelContext: modelContext)
                        } catch {
                            print("❌ Failed to delete all conversations: \(error)")
                        }
                    }
                }
            } message: {
                let conversationCount = groupedConversations.count
                let messageCount = allMessages.count
                Text("Delete all \(conversationCount) \(conversationCount == 1 ? "conversation" : "conversations") (\(messageCount) \(messageCount == 1 ? "message" : "messages"))? This cannot be undone. You'll free approximately \(String(format: "%.1f", estimatedStorageMB)) MB of storage.")
            }
            .alert("Storage Warning", isPresented: $showStorageWarning) {
                Button("View Conversations", role: .cancel) {
                    // User stays in the view to manage conversations
                }
                Button("Dismiss") {
                    // Just dismiss the warning
                }
            } message: {
                Text("Your conversation history is using approximately \(String(format: "%.1f", estimatedStorageMB)) MB of storage. Consider deleting old conversations to free up space.")
            }
        }
        .onAppear {
            selectedConversation = nil
            // Force refresh of query to ensure latest conversations are shown
            print("🔄 DEBUG: ConversationHistoryView appeared - query should auto-refresh")
            print("🔄 DEBUG: Current allMessages count: \(allMessages.count)")
            print("💾 DEBUG: Estimated storage: \(String(format: "%.2f", estimatedStorageMB)) MB")
            
            // Check storage threshold and show warning if exceeded
            // Only show once per session (use a flag)
            let warningShownKey = "storageWarningShownThisSession"
            if exceedsStorageThreshold && !UserDefaults.standard.bool(forKey: warningShownKey) {
                showStorageWarning = true
                UserDefaults.standard.set(true, forKey: warningShownKey)
            }
        }
        .onChange(of: allMessages.count) { oldCount, newCount in
            print("🔄 DEBUG: allMessages count changed from \(oldCount) to \(newCount)")
        }
        .refreshable {
            // Allow manual pull-to-refresh
            print("🔄 DEBUG: ConversationHistoryView manually refreshed")
            print("🔄 DEBUG: Current allMessages count: \(allMessages.count)")
            // @Query automatically updates, but this gives user control
        }
    }
}

struct ConversationGroup: Identifiable {
    let id = UUID()
    let conversationId: UUID
    let date: Date
    let startTime: Date
    let endTime: Date
    let messages: [LLMMessage]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: date)
        
        // If there are multiple conversations on the same day, include start time
        // We'll determine if we need this in the ConversationRow
        return dateStr
    }
    
    // Helper to format date with time for same-day conversations
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeStr = timeFormatter.string(from: startTime)
        
        return "\(dateStr), \(timeStr)"
    }
}

struct ConversationRow: View {
    let group: ConversationGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            HStack {
                Text(group.dateString)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Message count
                Text("\(group.messages.count) \(group.messages.count == 1 ? "message" : "messages")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Preview of last message
            if let lastMessage = group.messages.first {
                Text(lastMessage.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Time range
            HStack {
                Text(group.startTime, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if group.startTime != group.endTime {
                    Text(" - ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(group.endTime, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ConversationHistoryView()
        .environmentObject(HybridLLMManager())
}
