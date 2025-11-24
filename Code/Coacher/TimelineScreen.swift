//
//  TimelineScreen.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

enum DayKey: Hashable { case day(Int) } // -1..-7 past, 0 today

struct TimelineScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    
    @StateObject private var timeManager = TimeManager()
    @State private var entryToday = DailyEntry()
    @State private var showingNeedHelp = false
    @State private var showingSuccessCapture = false
    @State private var hasUnsavedChanges = false
    @State private var autoSaveTimer: Timer?

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea(.all)
                
                ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 7 PAST DAYS (collapsed, dimmed)
                        ForEach((1...7).reversed(), id: \.self) { back in
                            DayBucket(offset: -back, entries: entries)
                                .id(DayKey.day(-back))
                        }
                        
                        // TODAY (expanded morning)
                        DayBucket(offset: 0, entries: entries, entryToday: $entryToday, hasUnsavedChanges: $hasUnsavedChanges)
                            .id("todayBucket")
                        
                        // TONIGHT ONLY (no future placeholders)
                        TonightBucket(
                            entries: entries, 
                            entryToday: $entryToday, 
                            hasUnsavedChanges: $hasUnsavedChanges,
                            onCelebrationTrigger: { _, _ in }
                        )
                        .id("tonightBucket")
                        
                        // Success Flow Buttons
                        HStack(spacing: 12) {
                            // I Need Help Button
                            Button(action: { showingNeedHelp = true }) {
                                Label("I Need Help", systemImage: "hand.raised.fill")
                                    .font(.title3)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.helpButtonBlue)
                            .accessibilityLabel("I Need Help")
                            .accessibilityHint("Opens support options for when you're struggling with cravings or challenges")
                            
                            // I Did Great Button
                            Button(action: { showingSuccessCapture = true }) {
                                Label("I Did Great!", systemImage: "checkmark.circle.fill")
                                    .font(.title3)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .accessibilityLabel("I Did Great")
                            .accessibilityHint("Capture and celebrate a success or positive moment")
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .background(Color.appBackground)
                .onAppear { 
                    loadOrCreateToday()
                    proxy.scrollTo("todayBucket", anchor: .center)
                }
                .onReceive(notificationHandler.$shouldNavigateToSection) { section in
                    if let section = section {

                        
                        // Add a small delay to ensure the view is fully loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            switch section {
                            case "morningFocus":
                                // Scroll to today's morning focus section

                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("todayBucket", anchor: .center)
                                }
                            case "nightPrep":
                                // Scroll to tonight's prep section

                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("tonightBucket", anchor: .center)
                                }
                            default:
                                break
                            }
                        }
                        notificationHandler.shouldNavigateToSection = nil
                    }
                }


                .sheet(isPresented: $showingNeedHelp) {
                    NeedHelpView()
                }
                .sheet(isPresented: $showingSuccessCapture) {
                    SuccessCaptureView()
                }
                .overlay(
                    // Global celebration overlay - truly full screen
                    CelebrationOverlay(
                        isPresented: $celebrationManager.showingTinyCelebration,
                        title: "",
                        subtitle: celebrationManager.celebrationMessage
                    )
                )
                .overlay(
                    CelebrationOverlay(
                        isPresented: $celebrationManager.showingMediumCelebration,
                        title: "",
                        subtitle: celebrationManager.celebrationMessage
                    )
                )
                .overlay(
                    CelebrationOverlay(
                        isPresented: $celebrationManager.showingBigCelebration,
                        title: "",
                        subtitle: celebrationManager.celebrationMessage
                    )
                )
                .overlay(
                    // Milestone celebration overlay
                    MilestoneCelebrationOverlay(
                        isPresented: $celebrationManager.showingMilestoneCelebration,
                        streakCount: celebrationManager.milestoneStreakCount,
                        message: celebrationManager.milestoneMessage
                    )
                )
                }
            }
        }
    }
    
    private func loadOrCreateToday() {
        let startOfDay = timeManager.todayDate
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            entryToday = existing
        } else {
            entryToday = DailyEntry()
            entryToday.date = startOfDay
            context.insert(entryToday)
            try? context.save()
        }
    }
    
    private func scheduleAutoSave() {
        hasUnsavedChanges = true
        
        // Cancel existing timer
        autoSaveTimer?.invalidate()
        
        // Schedule auto-save after 2 seconds of inactivity
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            autoSave()
        }
    }
    
    private func autoSave() {
        try? context.save()
        hasUnsavedChanges = false
        
        // Record activity for milestone tracking
        celebrationManager.recordActivity()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveEntry() {
        try? context.save()
        hasUnsavedChanges = false
        
        // Record activity for milestone tracking
        celebrationManager.recordActivity()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    

}

#Preview {
    TimelineScreen()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self, CravingNote.self], inMemory: true)
}
