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
    @Query(sort: \LLMMessage.timestamp, order: .reverse) private var allMessages: [LLMMessage]
    
    // Group conversations by date (query from SwiftData)
    private var groupedConversations: [ConversationGroup] {
        let conversations = allMessages
            .filter { message in
                searchText.isEmpty || 
                message.content.localizedCaseInsensitiveContains(searchText)
            }
        
        let grouped = Dictionary(grouping: conversations) { message in
            Calendar.current.startOfDay(for: message.timestamp)
        }
        
        return grouped.map { date, messages in
            ConversationGroup(date: date, messages: messages.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                            Section(header: Text(group.dateString)) {
                                ForEach(group.messages.indices, id: \.self) { index in
                                    let message = group.messages[index]
                                    
                                    ConversationRow(
                                        message: message,
                                        isFirstInGroup: index == 0,
                                        isLastInGroup: index == group.messages.count - 1
                                    )
                                    .onTapGesture {
                                        // Scroll to this message in the main chat
                                        selectedConversation = group
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
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
            }
        }
        .onAppear {
            selectedConversation = nil
        }
    }
}

struct ConversationGroup: Identifiable {
    let id = UUID()
    let date: Date
    let messages: [LLMMessage]
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct ConversationRow: View {
    let message: LLMMessage
    let isFirstInGroup: Bool
    let isLastInGroup: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(message.role == .user ? Color.brandBlue : Color.secondary)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: message.role == .user ? "person.fill" : "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Role and timestamp
                HStack {
                    Text(message.role == .user ? "You" : "AI Coach")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Message content (truncated)
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
