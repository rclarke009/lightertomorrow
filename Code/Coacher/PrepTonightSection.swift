//
//  PrepTonightSection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct PrepTonightSection: View {
    @Environment(\.modelContext) private var context
    @Binding var entry: DailyEntry
    @Binding var todayEntry: DailyEntry // Add today's entry to access whatGotInTheWay
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var reminderManager = ReminderManager.shared
    
    @State private var newOtherItem = ""
    @State private var refreshTrigger = false
    @State private var showingPrepSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and info button
            HStack {
                Text("Night Prep")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button(action: { showingPrepSuggestions = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .brightBlue : .brandBlue)
                }
                
            }
            
            // Show reflection-based encouragement if user wrote about what got in the way
            if !todayEntry.whatGotInTheWay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(getReflectionEncouragement())
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
            } else {
                // Show generic encouragement when no reflection text
                Text("Let's do a prep to make tomorrow better.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)
            }

            // Default prep items (reordered as requested)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(visibleDefaultPrepItems, id: \.key) { item in
                    HStack {
                        Image(systemName: getDefaultItemCompletion(item.key) ? "checkmark.square.fill" : "square")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .onTapGesture {
                                toggleDefaultItem(item.key)
                            }
                        Text(item.text)
                            .onTapGesture {
                                toggleDefaultItem(item.key)
                            }
                        
                        Spacer()
                        
                        Button(action: { 
                            hideDefaultItem(item.key)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            
            // Custom prep items
            if !entry.safeCustomPrepItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    
                    ForEach(entry.safeCustomPrepItems, id: \.self) { item in
                        HStack {
                            Image(systemName: entry.safeCompletedCustomPrepItems.contains(item) ? "checkmark.square.fill" : "square")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .onTapGesture {
                                    toggleCustomItem(item)
                                }
                            Text(item)
                                .onTapGesture {
                                    toggleCustomItem(item)
                                }
                            
                            Spacer()
                            
                            Button(action: { 
                                deleteCustomItem(item)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Add new custom item
            HStack {
                // TextField("Add custom prep item...", text: $newOtherItem)
                //     .textFieldStyle(.roundedBorder)
                //     .foregroundColor(colorScheme == .dark ? .white : .primary)
                //     .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $newOtherItem)
                        .frame(minHeight: 60)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                        .padding(0)
                    
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                    )
                    
                    if newOtherItem.isEmpty {
                        Text(" Add custom prep item...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                )



                Button(action: addCustomItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(colorScheme == .dark ? .brightBlue : .white)
                        .font(.title2)
                }
                .disabled(newOtherItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Show reflection-based encouragement if user wrote about what got in the way
            if !entry.whatGotInTheWay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    Text(getReflectionEncouragement())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .id(refreshTrigger) // Force UI refresh when needed
        .onChange(of: todayEntry.whatGotInTheWay) { _, _ in 
            // Force UI refresh when user types in the "what got in the way" box
            refreshTrigger.toggle()
        }
        .sheet(isPresented: $showingPrepSuggestions) {
            NightPrepSuggestionsView()
        }
    }
    
    // MARK: - Default Prep Items Management
    
    private var visibleDefaultPrepItems: [(key: String, text: String)] {
        let allDefaultItems: [(key: String, text: String)] = [
            (key: "waterReady", text: "Water bottle ready"),
            (key: "breakfastPrepped", text: "Prep easy breakfast/snack"),
            (key: "stickyNotes", text: "Sticky notes for tomorrow"),
            (key: "preppedProduce", text: "Prepped produce")
        ]
        
        let hiddenItems = entry.safeHiddenDefaultPrepItems
        
        return allDefaultItems.filter { item in
            !hiddenItems.contains(item.key)
        }
    }
    
    private func getDefaultItemCompletion(_ key: String) -> Bool {
        switch key {
        case "waterReady": return entry.waterReady
        case "breakfastPrepped": return entry.breakfastPrepped
        case "stickyNotes": return entry.stickyNotes
        case "preppedProduce": return entry.preppedProduce
        default: return false
        }
    }
    
    private func toggleDefaultItem(_ key: String) {
        switch key {
        case "waterReady":
            entry.waterReady.toggle()
        case "breakfastPrepped":
            entry.breakfastPrepped.toggle()
        case "stickyNotes":
            entry.stickyNotes.toggle()
        case "preppedProduce":
            entry.preppedProduce.toggle()
        default:
            break
        }
        
        // Save the context
        try? context.save()
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func hideDefaultItem(_ key: String) {
        if entry.hiddenDefaultPrepItems == nil {
            entry.hiddenDefaultPrepItems = []
        }
        entry.hiddenDefaultPrepItems?.append(key)
        
        // Save the context
        try? context.save()
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func getDefaultItemText(_ key: String) -> String {
        switch key {
        case "waterReady": return "Water bottle ready"
        case "breakfastPrepped": return "Prep easy breakfast/snack"
        case "stickyNotes": return "Sticky notes for tomorrow"
        case "preppedProduce": return "Prepped produce"
        default: return key
        }
    }
    
    private func restoreDefaultItem(_ key: String) {
        entry.hiddenDefaultPrepItems?.removeAll { $0 == key }
        
        // Save the context
        try? context.save()
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    // MARK: - Custom Item Management
    
    private func addCustomItem() {
        let trimmedItem = newOtherItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return }
        

        
        // Add to DailyEntry's custom prep items (so it stays visible)
        if entry.customPrepItems == nil {
            entry.customPrepItems = []
        }
        entry.customPrepItems?.append(trimmedItem)
        
        // Also mark it as completed initially
        if entry.completedCustomPrepItems == nil {
            entry.completedCustomPrepItems = []
        }
        entry.completedCustomPrepItems?.append(trimmedItem)
        
        // Clear the input
        newOtherItem = ""
        

        
        // Save the context
        try? context.save()

        
        // Force UI refresh
        refreshTrigger.toggle()

    }
    
    private func toggleCustomItem(_ item: String) {
        if entry.safeCompletedCustomPrepItems.contains(item) {
            entry.completedCustomPrepItems?.removeAll { $0 == item }

        } else {
            if entry.completedCustomPrepItems == nil {
                entry.completedCustomPrepItems = []
            }
            entry.completedCustomPrepItems?.append(item)

        }
        
        // Save the context
        try? context.save()

        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func deleteCustomItems(offsets: IndexSet) {
        let itemsToDelete = offsets.map { entry.safeCustomPrepItems[$0] }
        
        // Remove from both arrays
        entry.customPrepItems?.remove(atOffsets: offsets)
        for item in itemsToDelete {
            entry.completedCustomPrepItems?.removeAll { $0 == item }
        }
        
        // Save the context
        try? context.save()
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func deleteCustomItem(_ item: String) {
        // Remove from both arrays
        entry.customPrepItems?.removeAll { $0 == item }
        entry.completedCustomPrepItems?.removeAll { $0 == item }
        
        // Save the context
        try? context.save()
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func getReflectionEncouragement() -> String {
        let reflectionText = todayEntry.whatGotInTheWay.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let encouragementTemplates = [
            "You wrote: '\(reflectionText)'. Let's do a prep to make that better tomorrow.",
            "You mentioned: '\(reflectionText)'. Let's set up something tomorrow to help with that.",
            "Today you noticed: '\(reflectionText)'. What might make tomorrow smoother?",
            "You identified: '\(reflectionText)'. Let's prepare for a smoother day tomorrow.",
            "You reflected on: '\(reflectionText)'. Time to set yourself up for success!",
            "You recognized: '\(reflectionText)'. Let's make tomorrow different."
        ]
        
        // Use a simple hash of the reflection text to consistently pick the same template
        let hash = reflectionText.hashValue
        let templateIndex = abs(hash) % encouragementTemplates.count
        
        return encouragementTemplates[templateIndex]
    }
}


#Preview {
    PrepTonightSection(
        entry: .constant(DailyEntry()),
        todayEntry: .constant(DailyEntry())
    )
    .padding()
}
