//
//  TodayView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    
    @StateObject private var timeManager = TimeManager()
    @State private var entry: DailyEntry = DailyEntry()
    @State private var showingNeedHelp = false
    @State private var showingSuccessCapture = false
    @State private var hasUnsavedChanges = false
    @State private var showWidgetGuide = false
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    @AppStorage("hasSeenWidgetGuide") private var hasSeenWidgetGuide = false
    @State private var autoSaveTimer: Timer?
    
    // Section expansion states
    @State private var lastNightPrepExpanded = false
    @State private var morningFocusCollapsed = false
    @State private var endOfDayCollapsed = true
    @State private var hasCompletedMorningToday = false
    @State private var shouldResetMorningFlow = false
    
    // Computed property to determine if widget banner should show
    private var shouldShowWidgetBanner: Bool {
        return appLaunchCount >= 2 && appLaunchCount <= 3 && !hasSeenWidgetGuide
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        
                        // Widget prompt banner
                        if shouldShowWidgetBanner {
                            WidgetPromptBanner(
                                onShowGuide: { showWidgetGuide = true },
                                onDismiss: { 
                                    hasSeenWidgetGuide = true
                                }
                            )
                        }
                    
            // Morning Focus - Primary in Day Phase
            if hasCompletedMorningToday && !shouldResetMorningFlow {
                // Show summary card when morning flow is completed
                MorningSummaryDisplayCard(entry: entry, onRestart: {
                    shouldResetMorningFlow = true
                })
            } else {
                SectionCard(
                    title: "Morning Focus (Today)",
                    icon: "sun.max.fill",
                    accent: .blue,
                    collapsed: $morningFocusCollapsed
                ) {
                            CareFirstMorningFocusSection(entry: $entry)
                                .onChange(of: entry.whyThisMatters) { _, _ in scheduleAutoSave() }
                                .onChange(of: entry.identityStatement) { _, _ in scheduleAutoSave() }
                                .onChange(of: entry.todaysFocus) { _, _ in scheduleAutoSave() }
                                .onChange(of: entry.stressResponse) { _, _ in scheduleAutoSave() }
                        }
            }
                    
                    // End-of-Day Check-In - Primary in Evening Phase
                    SectionCard(
                        title: "End-of-Day Check-In",
                        icon: "clock.fill",
                        accent: .teal,
                        collapsed: $endOfDayCollapsed,
                        dimmed: timeManager.isDayPhase
                    ) {
                        CareFirstEndOfDaySection(
                            entry: $entry,
                            onCelebrationTrigger: { _, _ in },
                            scrollProxy: proxy
                        )
                            .onChange(of: entry.didCareAction) { _, _ in hasUnsavedChanges = true }
                            .onChange(of: entry.whatHelpedCalm) { _, _ in hasUnsavedChanges = true }
                            .onChange(of: entry.comfortEatingMoment) { _, _ in hasUnsavedChanges = true }
                            .onChange(of: entry.smallWinsForTomorrow) { _, _ in hasUnsavedChanges = true }
                    }
                    
                    
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
                    .padding(.top)
                }
                .padding(.horizontal)
                .padding(.top, 2)
            }
            .background(
                Color.appBackground
                    .ignoresSafeArea(.all)
            )
            }
            //.navigationTitle("Good \(timeManager.greeting), \(UserDefaults.standard.string(forKey: "userName") ?? "friend")")
            .navigationTitle("Good \(timeManager.greeting)")
            .accessibilityLabel("Good \(timeManager.greeting)")

            //.navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Reset navigation bar appearance to default
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                // Track app launches for widget prompt
                appLaunchCount += 1
                
                loadOrCreateToday()
                setDefaultExpansionStates()
                checkMorningCompletionToday()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Refresh data when app becomes active to show current day's data
                loadOrCreateToday()
                // Don't reset expansion states - only reset on actual app launch
            }

            .sheet(isPresented: $showingNeedHelp) {
                NeedHelpView()
            }
            .sheet(isPresented: $showingSuccessCapture) {
                SuccessCaptureView()
            }
            .sheet(isPresented: $showWidgetGuide) {
                WidgetInstallationGuideView()
            }
            .overlay(
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
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func loadOrCreateToday() {
        let startOfDay = timeManager.todayDate
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            entry = existing
        } else {
            entry = DailyEntry()
            entry.date = startOfDay
            
            // Carry over yesterday's whatElseCouldHelp as today's stressResponse
            if let yesterdayEntry = getYesterdayEntry(), 
               let whatElseCouldHelp = yesterdayEntry.whatElseCouldHelp,
               !whatElseCouldHelp.isEmpty {
                entry.stressResponse = whatElseCouldHelp
            }
            
            context.insert(entry)
            try? context.save()
        }
        
        // Reset widget data for new day
        resetWidgetDataForNewDay()
    }
    
    private func getYesterdayEntry() -> DailyEntry? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: timeManager.todayDate) ?? timeManager.todayDate
        return entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })
    }
    
    

    
    private func getLastNightEntry() -> DailyEntry? {
        let startOfLastNight = timeManager.lastNightDate
        return entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfLastNight) })
    }
    
    private func setDefaultExpansionStates() {
        if timeManager.isDayPhase {
            morningFocusCollapsed = false  // Expanded during day
            endOfDayCollapsed = true       // Collapsed during day
        } else {
            morningFocusCollapsed = true   // Collapsed during evening
            endOfDayCollapsed = false      // Expanded during evening
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
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveEntry() {
        try? context.save()
        hasUnsavedChanges = false
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        hideKeyboard()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func checkMorningCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "morningCompletedDate") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            hasCompletedMorningToday = true
            // Announce morning completion to VoiceOver users
            UIAccessibility.post(notification: .announcement, argument: "Morning focus completed")
        } else {
            hasCompletedMorningToday = false
        }
    }
    
    private func resetWidgetDataForNewDay() {
        let userDefaults = UserDefaults(suiteName: "group.com.coacher.shared") ?? UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        let lastResetDate = userDefaults.object(forKey: "widgetDataLastResetDate") as? Date ?? Date.distantPast
        
        // Only reset if it's a new day
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: today) {
            userDefaults.set(0, forKey: "successNotesToday")
            userDefaults.set(today, forKey: "widgetDataLastResetDate")
        }
    }
    
}

// MARK: - Morning Summary Display Card

struct MorningSummaryDisplayCard: View {
    let entry: DailyEntry
    let onRestart: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .accessibilityHidden(true)
                
                Text("Morning Focus")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                // Show checkmark when completed
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .accessibilityLabel("Completed")
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.morningFocusBackground)
            )
            .clipShape(.rect(cornerRadius: 16, style: .continuous))

            // Summary content
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("You're ready to win the day")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                // Full plan summary as clean list
                VStack(spacing: 0) {
                    // Why This Matters
                    if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("Why This Matters")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I want to")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text(entry.whyThisMatters)
                                    .font(.body)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Divider
                    if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                       (entry.identityStatement?.isEmpty == false || !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    
                    // Identity Statement
                    if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("I Am Someone Who...")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Text(identity)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Divider
                    if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                       (!entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    
                    // Today's Focus
                    if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("Today's Focus")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Text(entry.todaysFocus)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Divider
                    if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                       !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    
                    // Stress Response
                    if !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("If Stressed")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            Text(entry.stressResponse)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Restart button (immediate action, no confirmation)
                Button(action: {
                    onRestart()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Restart Morning Focus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.morningFocusBackground)
        )
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}


#Preview {
    TodayView()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self], inMemory: true)
}
