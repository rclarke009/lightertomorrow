//
//  HistoryView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

enum TimelineItem: Identifiable {
    case entry(DailyEntry)
    case audioRecording(AudioRecording)
    case successNote(SuccessNote)
    case cravingNote(CravingNote)
    
    var id: String {
        switch self {
        case .entry(let entry):
            return "entry-\(entry.id.uuidString)"
        case .audioRecording(let recording):
            return "recording-\(recording.id.uuidString)"
        case .successNote(let note):
            return "success-\(note.id.uuidString)"
        case .cravingNote(let note):
            return "craving-\(note.id.uuidString)"
        }
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @Query(sort: \AudioRecording.date, order: .reverse) private var audioRecordings: [AudioRecording]
    @Query(sort: \SuccessNote.date, order: .reverse) private var successNotes: [SuccessNote]
    @Query(sort: \CravingNote.date, order: .reverse) private var cravingNotes: [CravingNote]
    @State private var isLoading = false
    @State private var refreshTimer: Timer?
    @State private var cachedTimelineItems: [TimelineItem] = []
    
    init() {
        print("📱 DEBUG: HistoryView initialized")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Heatmap
                    StreakHeatmap(entryDates: Set(entries.map { Calendar.current.startOfDay(for: $0.date) }))
                        .padding(.horizontal)
                    
                    // Weekly Completion Ring
                    WeeklyCompletionRing(entries: entries)
                        .padding(.horizontal)
                    
                    // Combined Timeline (Entries + Audio Recordings)
                    LazyVStack(spacing: 12) {
                        if cachedTimelineItems.isEmpty && !isLoading {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "clock")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                
                                Text("No History Yet")
                                    .font(.title2)
                                    .bold()
                                
                                Text("Your daily entries and success moments will appear here")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(cachedTimelineItems, id: \.id) { item in
                                switch item {
                                case .entry(let entry):
                                    EntryRowView(entry: entry)
                                case .audioRecording(let recording):
                                    AudioRecordingRow(recording: recording)
                                case .successNote(let note):
                                    SuccessNoteRow(note: note)
                                case .cravingNote(let note):
                                    CravingNoteRow(note: note)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("History")
            .background(
                Color.appBackground
                    .ignoresSafeArea(.all)
            )
            .onAppear {
                isLoading = true
                updateTimelineCache()
                // Add a small delay to prevent race conditions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isLoading = false
                }
            }
            .refreshable {
                // Force refresh of SwiftData queries
                isLoading = true
                updateTimelineCache()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isLoading = false
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
    }
    
    private func createCombinedTimeline() -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Add daily entries
        for entry in entries {
            items.append(.entry(entry))
        }
        
        // Add audio recordings
        for recording in audioRecordings {
            items.append(.audioRecording(recording))
        }
        
        // Add success notes
        for note in successNotes {
            items.append(.successNote(note))
        }
        
        // Add craving notes
        for note in cravingNotes {
            items.append(.cravingNote(note))
        }
        
        // Sort by date (most recent first)
        let sortedItems = items.sorted { first, second in
            let firstDate: Date
            let secondDate: Date
            
            switch first {
            case .entry(let entry):
                firstDate = entry.date
            case .audioRecording(let recording):
                firstDate = recording.date
            case .successNote(let note):
                firstDate = note.date
            case .cravingNote(let note):
                firstDate = note.date
            }
            
            switch second {
            case .entry(let entry):
                secondDate = entry.date
            case .audioRecording(let recording):
                secondDate = recording.date
            case .successNote(let note):
                secondDate = note.date
            case .cravingNote(let note):
                secondDate = note.date
            }
            
            return firstDate > secondDate
        }
        
        return sortedItems
    }
    
    private func updateTimelineCache() {
        print("🔄 DEBUG: Updating timeline cache")
        print("🔄 DEBUG: SuccessNotes count: \(successNotes.count)")
        for (index, note) in successNotes.enumerated() {
            print("🔄 DEBUG: SuccessNote \(index): ID=\(note.id), text='\(note.text)', date=\(note.date)")
        }
        cachedTimelineItems = createCombinedTimeline()
        print("🔄 DEBUG: Cached timeline items count: \(cachedTimelineItems.count)")
    }
    
    private func debugData() {
        print("🔍 DEBUG: Manual data query test")
        
        // Try to manually query all data types
        do {
            let descriptor = FetchDescriptor<DailyEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let allEntries = try context.fetch(descriptor)
            print("🔍 DEBUG: Manual DailyEntry fetch: \(allEntries.count) entries")
            
            let successDescriptor = FetchDescriptor<SuccessNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let allSuccessNotes = try context.fetch(successDescriptor)
            print("🔍 DEBUG: Manual SuccessNote fetch: \(allSuccessNotes.count) notes")
            
            let cravingDescriptor = FetchDescriptor<CravingNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let allCravingNotes = try context.fetch(cravingDescriptor)
            print("🔍 DEBUG: Manual CravingNote fetch: \(allCravingNotes.count) notes")
            
            let audioDescriptor = FetchDescriptor<AudioRecording>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let allAudioRecordings = try context.fetch(audioDescriptor)
            print("🔍 DEBUG: Manual AudioRecording fetch: \(allAudioRecordings.count) recordings")
            
        } catch {
            print("❌ DEBUG: Error in manual fetch: \(error)")
        }
    }
}

struct EntryRowView: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink(destination: EntryDetailView(entry: entry)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and completion status
                HStack {
                    Text(entry.date, style: .date)
                        .font(.headline)
                    
                    Spacer()
                    
                    if entry.hasAnyAction {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                if entry.hasAnyAction {
                    VStack(alignment: .leading, spacing: 12) {
                        // Morning Focus Summary
                        if entry.hasAnyMorningFocus {
                            MorningSummaryCard(entry: entry)
                        }
                        
                        // End of Day Summary
                        if entry.hasAnyEndOfDay {
                            EndOfDaySummaryCard(entry: entry)
                        }
                        
                        // Night Prep Summary
                        if entry.hasAnyNightPrep {
                            NightPrepSummaryCard(entry: entry)
                        }
                    }
                } else {
                    Text("No actions logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Card Components

struct MorningSummaryCard: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Morning Focus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if !entry.whyThisMatters.isEmpty {
                    SummaryItem(
                        label: "Why this matters:",
                        text: entry.whyThisMatters,
                        color: .orange
                    )
                }
                
                if let identity = entry.identityStatement, !identity.isEmpty {
                    SummaryItem(
                        label: "Identity:",
                        text: identity,
                        color: .orange
                    )
                }
                
                if !entry.todaysFocus.isEmpty {
                    SummaryItem(
                        label: "Today's focus:",
                        text: entry.todaysFocus,
                        color: .orange
                    )
                }
                
                if !entry.stressResponse.isEmpty {
                    SummaryItem(
                        label: "Stress response:",
                        text: entry.stressResponse,
                        color: .orange
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct EndOfDaySummaryCard: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                Text("End of Day")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                Spacer()
                
                if let didCare = entry.didCareAction {
                    Text(didCare ? "✓ Followed plan" : "• Noted challenge")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if !entry.whatHelpedCalm.isEmpty {
                    SummaryItem(
                        label: "What helped:",
                        text: entry.whatHelpedCalm,
                        color: .green
                    )
                }
                
                if let comfortMoment = entry.comfortEatingMoment, !comfortMoment.isEmpty {
                    SummaryItem(
                        label: "Comfort eating moment:",
                        text: comfortMoment,
                        color: .green
                    )
                }
                
                if !entry.smallWinsForTomorrow.isEmpty {
                    SummaryItem(
                        label: "Tomorrow's prep:",
                        text: entry.smallWinsForTomorrow,
                        color: .green
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
}

struct NightPrepSummaryCard: View {
    let entry: DailyEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Night Prep")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                let prepItems = getPrepItems()
                if !prepItems.isEmpty {
                    SummaryItem(
                        label: "Prepared:",
                        text: prepItems.joined(separator: ", "),
                        color: .blue
                    )
                }
                
                if !entry.nightOther.isEmpty {
                    SummaryItem(
                        label: "Other:",
                        text: entry.nightOther,
                        color: .blue
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func getPrepItems() -> [String] {
        var items: [String] = []
        
        if entry.stickyNotes { items.append("sticky notes") }
        if entry.preppedProduce { items.append("produce") }
        if entry.waterReady { items.append("water") }
        if entry.breakfastPrepped { items.append("breakfast") }
        
        return items
    }
}

struct SummaryItem: View {
    let label: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(text)
                .font(.headline)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



struct EntryDetailView: View {
    let entry: DailyEntry
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NightPrepSection(entry: .constant(entry))
                Divider()
                CareFirstMorningFocusSection(entry: .constant(entry))
                Divider()
                CareFirstEndOfDaySection(
                    entry: .constant(entry),
                    onCelebrationTrigger: { _, _ in },
                    scrollProxy: nil
                )
            }
            .padding()
        }
        .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyCompletionRing: View {
    let entries: [DailyEntry]
    @Environment(\.colorScheme) private var colorScheme
    
    private var weeklyProgress: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let daysThisWeek = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
        
        let completedDays = daysThisWeek.filter { date in
            entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: date) && entry.hasAnyAction
            }
        }.count
        
        return Double(completedDays) / 7.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("This Week")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: weeklyProgress)
                    .stroke(Color.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: weeklyProgress)
                
                VStack {
                    Text("\(Int(weeklyProgress * 100))%")
                        .font(.title2)
                        .bold()
                    Text("\(Int(weeklyProgress * 7))/7 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
    }
}





struct SuccessNoteRow: View {
    let note: SuccessNote
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: note.type.icon)
                    .foregroundColor(note.type.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.type.displayName)
                        .font(.headline)
                        .foregroundColor(note.type.color)
                    
                    Text(note.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if !note.text.isEmpty {
                Text(note.text)
                    .font(.body)
                    .padding(.leading, 32)
            }
            
            if note.keptAudio && note.audioURL != nil && note.text.isEmpty {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                    Text("Audio recording available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
    }
}

struct CravingNoteRow: View {
    let note: CravingNote
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: note.type.icon)
                    .foregroundColor(note.type.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.type.displayName)
                        .font(.headline)
                        .foregroundColor(note.type.color)
                    
                    Text(note.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if !note.text.isEmpty {
                Text(note.text)
                    .font(.body)
                    .padding(.leading, 32)
            }
            
            if note.keptAudio && note.audioURL != nil && note.text.isEmpty {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                    Text("Audio recording available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self, AudioRecording.self, SuccessNote.self, CravingNote.self, EmotionalTakeoverNote.self, HabitHelperNote.self], inMemory: true)
}
