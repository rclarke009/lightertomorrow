//
//  DayBucket.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct DayBucket: View {
    let offset: Int // -1..-7 for past, 0 for today
    let entries: [DailyEntry]
    var entryToday: Binding<DailyEntry>? = nil
    var hasUnsavedChanges: Binding<Bool>? = nil
    
    @StateObject private var timeManager = TimeManager()
    @State private var lastNightPrepCollapsed = true
    @State private var hasCompletedMorningToday = false
    
    // Separate state for past days to allow expansion
    @State private var pastLastNightPrepCollapsed = true
    @State private var pastMorningFocusCollapsed = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header label
            if offset == 0 {
                Text("Today")
                    .font(.title3.weight(.semibold))
            } else {
                Text(formattedDate(for: offset))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            if offset < 0 {
                // PAST: collapsed + dimmed, but expandable to show journey
                SectionCard(
                    title: "Last Night's Prep",
                    icon: "moon.stars.fill",
                    accent: .dimmedGreen,
                    collapsed: $pastLastNightPrepCollapsed,
                    dimmed: true
                ) {
                    PastNightPrepPreview(offset: offset)
                }
                .onTapGesture {
                    withAnimation(.snappy) {
                        pastLastNightPrepCollapsed.toggle()
                    }
                }
                
                SectionCard(
                    title: "Morning Focus",
                    icon: "sun.max.fill",
                    accent: .goldenYellow,
                    collapsed: $pastMorningFocusCollapsed,
                    dimmed: true
                ) {
                    PastMorningFocusPreview(offset: offset)
                }
                .onTapGesture {
                    withAnimation(.snappy) {
                        pastMorningFocusCollapsed.toggle()
                    }
                }
            } else {
                // TODAY
                SectionCard(
                    title: "Last Night's Prep (for Today)",
                    icon: "moon.stars.fill",
                    accent: .dimmedGreen,
                    collapsed: $lastNightPrepCollapsed,
                    dimmed: true
                ) {
                    LastNightPrepReviewView(entry: getLastNightEntry())
                }
                .onTapGesture {
                    withAnimation(.snappy) {
                        lastNightPrepCollapsed.toggle()
                    }
                }
                
                MorningFocusCard(
                    title: "Morning Focus",
                    icon: "sun.max.fill",
                    isCompleted: hasCompletedMorningToday
                ) {
                    if let entryToday = entryToday, let hasUnsavedChanges = hasUnsavedChanges {
                        CareFirstMorningFocusSection(entry: entryToday)
                            .onChange(of: entryToday.wrappedValue.identityStatement) { _, _ in hasUnsavedChanges.wrappedValue = true }
                            .onChange(of: entryToday.wrappedValue.todaysFocus) { _, _ in hasUnsavedChanges.wrappedValue = true }
                            .onChange(of: entryToday.wrappedValue.stressResponse) { _, _ in hasUnsavedChanges.wrappedValue = true }
                            .onChange(of: entryToday.wrappedValue.optionalSupportiveSnack) { _, _ in hasUnsavedChanges.wrappedValue = true }
                    } else {
                        CareFirstMorningFocusSection(entry: .constant(DailyEntry()))
                    }
                }
//                .onTapGesture {
//                    withAnimation(.snappy) {
//                        morningFocusCollapsed.toggle()
//                    }
//                }
            }
        }
        .onAppear {
            setDefaultCollapsedStates()
            checkMorningCompletionToday()
        }
    }
    
    private func setDefaultCollapsedStates() {
        if offset == 0 {
            // Today: Morning Focus is always visible (no collapse)
            lastNightPrepCollapsed = true
        } else {
            // Past days: both collapsed by default
            pastMorningFocusCollapsed = true
            pastLastNightPrepCollapsed = true
        }
    }
    
    private func formattedDate(for offset: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "EEE • MMM d"
        return f.string(from: date)
    }
    
    private func checkMorningCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "morningCompletedDate") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            hasCompletedMorningToday = true
        } else {
            hasCompletedMorningToday = false
        }
    }
    
    private func getLastNightEntry() -> DailyEntry? {
        let startOfLastNight = timeManager.lastNightDate
        return entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfLastNight) })
    }
}

#Preview {
    VStack(spacing: 20) {
        // Past day
        DayBucket(offset: -1, entries: [])
        
        // Today
        DayBucket(offset: 0, entries: [], entryToday: .constant(DailyEntry()), hasUnsavedChanges: .constant(false))
    }
    .padding()
}
