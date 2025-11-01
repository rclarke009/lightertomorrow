//
//  NightPrepSection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct NightPrepSection: View {
    @Binding var entry: DailyEntry
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var reminderManager = ReminderManager.shared
    
    @State private var newOtherItem = ""
    @State private var refreshTrigger = false
    @State private var showingPrepSuggestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Night Prep")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button(action: { showingPrepSuggestions = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.brightBlue)
                }
                
            }
            
            // Default prep items (reordered as requested)
            if !visibleDefaultPrepItems.isEmpty {
                List {
                    ForEach(visibleDefaultPrepItems, id: \.key) { item in
                        HStack {
                            Image(systemName: getDefaultItemCompletion(item.key) ? "checkmark.square.fill" : "square")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .onTapGesture {
                                    print("🔍 DEBUG: Tapped checkbox for: \(item.key)")
                                    toggleDefaultItem(item.key)
                                }
                            Text(item.text)
                                .onTapGesture {
                                    print("🔍 DEBUG: Tapped text for: \(item.key)")
                                    toggleDefaultItem(item.key)
                                }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                print("🔍 DEBUG: Swipe delete button tapped for item: \(item.key)")
                                hideDefaultItem(item.key)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .onAppear {
                    print("🔍 DEBUG: Rendering \(visibleDefaultPrepItems.count) visible items")
                    for item in visibleDefaultPrepItems {
                        print("🔍 DEBUG: Rendering item: \(item.key) - \(item.text)")
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
                        }
                    }
                    .onDelete(perform: deleteCustomItems)
                }
            }
            
            // Show hidden items section if any are hidden
            if !entry.safeHiddenDefaultPrepItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hidden Items")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    ForEach(entry.safeHiddenDefaultPrepItems, id: \.self) { hiddenKey in
                        HStack {
                            Text(getDefaultItemText(hiddenKey))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button(action: { restoreDefaultItem(hiddenKey) }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.brightBlue)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Add new custom item
            HStack {
                TextField("Add custom prep item...", text: $newOtherItem)
                    .textFieldStyle(.roundedBorder)
                
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .id(refreshTrigger) // Force UI refresh when needed
        .onChange(of: entry.waterReady) { _, _ in checkNightPrepCompletion() }
        .onChange(of: entry.breakfastPrepped) { _, _ in checkNightPrepCompletion() }
        .onChange(of: entry.stickyNotes) { _, _ in checkNightPrepCompletion() }
        .onChange(of: entry.preppedProduce) { _, _ in checkNightPrepCompletion() }
        .onChange(of: entry.completedCustomPrepItems) { _, _ in checkNightPrepCompletion() }
        .onChange(of: entry.hiddenDefaultPrepItems) { _, _ in 
            // Force UI refresh when items are hidden
            refreshTrigger.toggle()
        }
        .onChange(of: entry.whatGotInTheWay) { _, _ in 
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
        print("🔍 DEBUG: All default items: \(allDefaultItems.map { $0.key })")
        print("🔍 DEBUG: Hidden items: \(hiddenItems)")
        
        let visible = allDefaultItems.filter { item in
            !hiddenItems.contains(item.key)
        }
        
        print("🔍 DEBUG: Visible items: \(visible.map { $0.key })")
        return visible
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
        print("🔍 DEBUG: hideDefaultItem called with key: \(key)")
        print("🔍 DEBUG: Current hidden items before: \(entry.safeHiddenDefaultPrepItems)")
        
        if entry.hiddenDefaultPrepItems == nil {
            entry.hiddenDefaultPrepItems = []
        }
        entry.hiddenDefaultPrepItems?.append(key)
        
        print("🔍 DEBUG: Current hidden items after: \(entry.safeHiddenDefaultPrepItems)")
        
        // Save the context
        try? context.save()
        print("🔍 DEBUG: Context saved after hiding item")
        
        // Force UI refresh
        refreshTrigger.toggle()
        print("🔍 DEBUG: Refresh triggered: \(refreshTrigger)")
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
    
    private func deleteDefaultItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { visibleDefaultPrepItems[$0].key }
        
        // Add to hidden items
        if entry.hiddenDefaultPrepItems == nil {
            entry.hiddenDefaultPrepItems = []
        }
        entry.hiddenDefaultPrepItems?.append(contentsOf: itemsToDelete)
        
        print("🔍 DEBUG: NightPrepSection - Hidden default items: \(itemsToDelete)")
        
        // Save the context
        try? context.save()
        print("🔍 DEBUG: NightPrepSection - Context saved after delete")
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    // MARK: - Custom Item Management
    
    private func addCustomItem() {
        let trimmedItem = newOtherItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return }
        
        // print("🔍 DEBUG: NightPrepSection - Adding custom item: '\(trimmedItem)'")
        //             print("🔍 DEBUG: NightPrepSection - Current custom items: \(entry.safeCustomPrepItems.count)")
        
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
        
        // print("🔍 DEBUG: NightPrepSection - After adding, custom items: \(entry.safeCustomPrepItems.count)")
        // print("🔍 DEBUG: NightPrepSection - Custom items array: \(entry.safeCustomPrepItems)")
        
        // Save the context
        try? context.save()
        // print("🔍 DEBUG: NightPrepSection - Context saved")
        
        // Force UI refresh
        refreshTrigger.toggle()
        // print("🔍 DEBUG: NightPrepSection - Refresh triggered: \(refreshTrigger)")
    }
    
    private func toggleCustomItem(_ item: String) {
        if entry.safeCompletedCustomPrepItems.contains(item) {
            entry.completedCustomPrepItems?.removeAll { $0 == item }
            print("🔍 DEBUG: NightPrepSection - Toggled custom item: \(item), now checked: false")
        } else {
            if entry.completedCustomPrepItems == nil {
                entry.completedCustomPrepItems = []
            }
            entry.completedCustomPrepItems?.append(item)
            print("🔍 DEBUG: NightPrepSection - Toggled custom item: \(item), now checked: true")
        }
        
        // Save the context
        try? context.save()
        print("🔍 DEBUG: NightPrepSection - Context saved after toggle")
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func deleteCustomItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { entry.safeCustomPrepItems[$0] }
        
        // Remove from both arrays
        entry.customPrepItems?.remove(atOffsets: offsets)
        for item in itemsToDelete {
            entry.completedCustomPrepItems?.removeAll { $0 == item }
        }
        
        // print("🔍 DEBUG: NightPrepSection - Deleted custom items: \(itemsToDelete)")
        
        // Save the context
        try? context.save()
        // print("🔍 DEBUG: NightPrepSection - Context saved after delete")
        
        // Force UI refresh
        refreshTrigger.toggle()
    }
    
    private func checkNightPrepCompletion() {
        // Check if any visible night prep items are completed
        let hasCompletedDefaultItems = visibleDefaultPrepItems.contains { item in
            getDefaultItemCompletion(item.key)
        }
        let hasCompletedCustomItems = !entry.safeCompletedCustomPrepItems.isEmpty
        let hasCompletedItems = hasCompletedDefaultItems || hasCompletedCustomItems
        
        // If any items are completed, cancel today's reminder and reschedule for tomorrow
        if hasCompletedItems {
            reminderManager.cancelNightPrepReminder()
            // Reschedule the reminder for tomorrow since user completed prep early
            Task {
                await reminderManager.rescheduleNightPrepReminderForTomorrow()
            }
        }
    }
    
    private func getReflectionEncouragement() -> String {
        let reflectionText = entry.whatGotInTheWay.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let encouragementTemplates = [
            "You wrote: '\(reflectionText)'. Let's set up something tomorrow to help with that.",
            "Today you noticed: '\(reflectionText)'. What will make tomorrow better?",
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

struct NightPrepSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProblem: PrepProblem? = nil
    
    enum PrepProblem: String, CaseIterable, Identifiable {
        case foodTemptations = "foodTemptations"
        case timeCrunch = "timeCrunch"
        case lowEnergy = "lowEnergy"
        case socialTriggers = "socialTriggers"
        case notSure = "notSure"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .foodTemptations: return "🍫 Food Temptations"
            case .timeCrunch: return "⏰ Time Crunch"
            case .lowEnergy: return "😴 Low Energy"
            case .socialTriggers: return "👥 Social Triggers"
            case .notSure: return "❓ Not Sure"
            }
        }
        
        var description: String {
            switch self {
            case .foodTemptations: return "I keep grabbing junk food or sugary snacks"
            case .timeCrunch: return "I skip meals or grab fast food when I'm rushed"
            case .lowEnergy: return "I get tired, stressed, or snack late at night"
            case .socialTriggers: return "I overeat when with friends, coworkers, or at restaurants"
            case .notSure: return "I'm not sure what trips me up"
            }
        }
        
        var solutions: [String] {
            switch self {
            case .foodTemptations:
                return [
                    "Put chips/cookies out of sight or in a high cupboard",
                    "Prep cut veggies/fruit and place them front-and-center in the fridge",
                    "Portion one small treat into a baggie so you control the amount",
                    "Put a sticky note on the fridge/pantry: 'Water first'",
                    "Swap candy in a dish for fruit or nuts",
                    "Toss or donate one junk item tonight"
                ]
            case .timeCrunch:
                return [
                    "Pack lunch or snacks in a bag tonight",
                    "Prep overnight oats, hard-boiled eggs, or a protein box",
                    "Set water bottle, coffee mug, or vitamins where you'll see them",
                    "Lay out tomorrow's breakfast dish/utensils to save time",
                    "Write one quick 'fallback meal' idea for tomorrow",
                    "Block 10 minutes on your calendar for lunch"
                ]
            case .lowEnergy:
                return [
                    "Plan a protein snack for mid-afternoon",
                    "Set a bedtime reminder on your phone",
                    "Choose a 2-minute 'reset' for tomorrow (walk, stretch, deep breath)",
                    "Put herbal tea by the kettle for a calming evening ritual",
                    "Write down one stressor and one small thing you can do about it",
                    "Keep water at your bedside to start the day hydrated"
                ]
            case .socialTriggers:
                return [
                    "Text a friend to meet at a healthier restaurant",
                    "Decide on your order before you get there",
                    "Ask a coworker to walk instead of snack break",
                    "Pack an extra snack to avoid arriving hungry",
                    "Tell someone your swap goal for tomorrow",
                    "Invite a friend/family member to prep with you"
                ]
            case .notSure:
                return [
                    "Put a full water bottle in the fridge or on your nightstand",
                    "Put fruit or veggies at eye level in the fridge",
                    "Prep one protein-rich snack (boiled egg, cheese stick, yogurt cup)",
                    "Write your 'why' or swap on a sticky note for tomorrow",
                    "Put sneakers, yoga mat, or resistance band where you'll see them",
                    "Set a bedtime reminder on your phone"
                ]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if selectedProblem == nil {
                    // Problem selection view
                    VStack(spacing: 20) {
                        Text("Think about what usually makes tomorrow harder. Tap one:")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(PrepProblem.allCases) { problem in
                                Button(action: { selectedProblem = problem }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(problem.title)
                                            .font(.headline)
                                            .foregroundColor(.brightBlue)
                                        
                                        Text(problem.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Solutions view
                    VStack(spacing: 20) {
                        Text("Here are some prep ideas for \(selectedProblem?.title ?? ""):")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(selectedProblem?.solutions ?? [], id: \.self) { solution in
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        
                                        Text(solution)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button("Back to Problems") {
                            selectedProblem = nil
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.brightBlue)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Night Prep Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brightBlue)
                }
            }
        }
    }
}

#Preview {
    NightPrepSection(entry: .constant(DailyEntry()))
}
