//
//  SettingsView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @EnvironmentObject private var reminderManager: ReminderManager
    @EnvironmentObject private var hybridManager: HybridLLMManager
    @Environment(\.colorScheme) private var colorScheme
    @Query private var achievements: [Achievement]
    @StateObject private var mlcManager = SimplifiedMLCManager()
    @State private var showOnboarding = false
    @AppStorage("useCloudAI") private var useCloudAI = false
    
    @AppStorage("showStreakWidgets") private var showStreakWidgets = true
    @AppStorage("nightPrepReminder") private var nightPrepReminder = true
    @AppStorage("morningFocusReminder") private var morningFocusReminder = true
    @State private var nightPrepTime: Date = Date()
    @State private var morningFocusTime: Date = Date()
    @State private var showAdvancedAISettings = false
    @State private var showWidgetGuide = false
    
    var body: some View {
        NavigationView {
            List {
                remindersSection
                
                widgetSection
                
                aiCoachComingSoonSection
                
                personalizationSection
                
                aiConfigurationSection
                
                gamificationSection
                
                aiCoachModelSection
                
                dataPrivacySection
                
                aboutSection
                
                legalSection
            }
            .navigationTitle("Settings")
            .background(
                Color.appBackground
                    .ignoresSafeArea(.all)
            )
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                loadSavedTimes()
            }
            .sheet(isPresented: $showWidgetGuide) {
                WidgetInstallationGuideView()
            }
            .onChange(of: nightPrepTime) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "nightPrepTime")
            }
            .onChange(of: morningFocusTime) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "morningFocusTime")
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .onAppear {
                    print("🔄 DEBUG: OnboardingView fullScreenCover appeared")
                }
        }
    }
    
    // MARK: - Section Views
    
    private var remindersSection: some View {
        Section("Reminders") {
                    Toggle("Night Prep Reminder", isOn: $nightPrepReminder)
                        .onChange(of: nightPrepReminder) { _, _ in
                            Task {
                                await reminderManager.updateReminders()
                            }
                        }
                    if nightPrepReminder {
                        DatePicker("Time", selection: $nightPrepTime, displayedComponents: .hourAndMinute)
                            .onChange(of: nightPrepTime) { _, _ in
                                Task {
                                    await reminderManager.updateReminders()
                                }
                            }
                    }
                    
                    Toggle("Morning Focus Reminder", isOn: $morningFocusReminder)
                        .onChange(of: morningFocusReminder) { _, _ in
                            Task {
                                await reminderManager.updateReminders()
                            }
                        }
                    if morningFocusReminder {
                        DatePicker("Time", selection: $morningFocusTime, displayedComponents: .hourAndMinute)
                            .onChange(of: morningFocusTime) { _, _ in
                                Task {
                                    await reminderManager.updateReminders()
                                }
                            }
                    }
                }
    }
    
    private var widgetSection: some View {
        Section(header: Text("Home Screen Widget")) {
                    Button(action: { showWidgetGuide = true }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(.blue)
                            Text("How to Add Widget")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel("How to add widget")
                    .accessibilityHint("Opens guide for adding home screen widget")
                }
    }
    
    private var aiCoachComingSoonSection: some View {
        Section("AI Coach") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                    Text("Coming Soon")
                        .font(.headline)
                }
                Text("Your AI coach will be available soon to help guide you on your wellness journey.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var personalizationSection: some View {
        Section("Personalization") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: Binding(
                            get: { UserDefaults.standard.string(forKey: "userName") ?? "" },
                            set: { UserDefaults.standard.set($0, forKey: "userName") }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(colorScheme == .dark ? .white : .secondary)
                        .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                        .accessibilityLabel("Name")
                        .accessibilityHint("Enter your name for personalization")
                    }
                    
                    Button(action: {
                        print("🔄 DEBUG: Replay Onboarding button tapped")
                        showOnboarding = true
                        print("🔄 DEBUG: showOnboarding set to true")
                    }) {
                        Text("Replay Onboarding")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Replay Onboarding")
                    .accessibilityHint("Restart the app introduction and setup process")
                }
    }
    
    private var aiConfigurationSection: some View {
        Section {
                    Button(action: {
                        showAdvancedAISettings.toggle()
                    }) {
                        HStack {
                            Text("Advanced AI Settings")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Image(systemName: showAdvancedAISettings ? "chevron.down" : "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if showAdvancedAISettings {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("OpenAI API Key")
                                Spacer()
                                TextField("sk-...", text: Binding(
                                    get: { KeychainManager.shared.getOpenAIKey() ?? "" },
                                    set: { 
                                        if $0.isEmpty {
                                            _ = KeychainManager.shared.deleteOpenAIKey()
                                        } else {
                                            _ = KeychainManager.shared.storeOpenAIKey($0)
                                        }
                                    }
                                ))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(colorScheme == .dark ? .white : .secondary)
                                .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                                .accessibilityLabel("OpenAI API Key")
                                .accessibilityHint("Enter your OpenAI API key for enhanced AI features")
                            }
                            
                            if useCloudAI {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Online AI enabled")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("Add API key to enable online AI features")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("AI Configuration")
                }
    }
    
    private var gamificationSection: some View {
        Section("Gamification") {
                    Toggle("Show animations", isOn: $celebrationManager.animationsEnabled)
                    
                    Toggle("Show streak widgets", isOn: $showStreakWidgets)
                    
                    if !achievements.isEmpty {
                        HStack {
                            Text("Achievements earned")
                            Spacer()
                            Text("\(achievements.count)")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Reset achievements") {
                            resetAchievements()
                        }
                        .foregroundStyle(.red)
                    }
                }
    }
    
    private var aiCoachModelSection: some View {
        Section("AI Coach") {
                    HStack {
                        Text("Model Status")
                        Spacer()
                        Text(mlcManager.modelStatus)
                            .foregroundStyle(.secondary)
                    }
                    
                    if mlcManager.isModelLoaded {
                        HStack {
                            Text("Model")
                            Spacer()
                            Text("Llama-2-7B")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Quantization")
                            Spacer()
                            Text("Q4F16")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !mlcManager.isModelLoaded && !mlcManager.isLoading {
                        Button("Load Model") {
                            Task {
                                await mlcManager.loadModel()
                            }
                        }
                        .foregroundColor(.brandBlue)
                    }
                    
                    if mlcManager.errorMessage != nil {
                        Text(mlcManager.errorMessage ?? "")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
    }
    
    private var dataPrivacySection: some View {
        Section("Data & Privacy") {
                    Button("Export data") {
                        exportData()
                    }
                    .foregroundColor(.leafGreen)
                    
                    Button("Import data") {
                        importData()
                    }
                    .foregroundColor(.leafYellow)
                    
                    Button("Clear all data") {
                        clearAllData()
                    }
                    .foregroundStyle(.red)
                }
    }
    
    private var aboutSection: some View {
        Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.lightertomorrow.com/public/privacy-policy.html")!)
                        .foregroundColor(.brandBlue)
                    
                    Link("Terms of Service", destination: URL(string: "https://www.lightertomorrow.com/public/terms-of-service.html")!)
                        .foregroundColor(.brandBlue)
                }
    }
    
    private var legalSection: some View {
        Section {
            Text("AI Disclaimer")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Legal")
        } footer: {
            Text("AI-generated responses may contain errors or inaccuracies. This app provides wellness coaching for informational purposes only and is not a substitute for professional medical, mental health, or therapeutic advice. Always consult qualified healthcare providers for medical concerns.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadSavedTimes() {
        if let savedNightTime = UserDefaults.standard.object(forKey: "nightPrepTime") as? Date {
            nightPrepTime = savedNightTime
        } else {
            let calendar = Calendar.current
            let defaultNightTime = calendar.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
            nightPrepTime = defaultNightTime
        }
        
        if let savedMorningTime = UserDefaults.standard.object(forKey: "morningFocusTime") as? Date {
            morningFocusTime = savedMorningTime
        } else {
            let calendar = Calendar.current
            let defaultMorningTime = calendar.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
            morningFocusTime = defaultMorningTime
        }
    }
    
    private func resetAchievements() {
        // TODO: Show confirmation dialog
        for achievement in achievements {
            context.delete(achievement)
        }
        try? context.save()
    }
    
    private func exportData() {
        // TODO: Implement data export
    }
    
    private func importData() {
        // TODO: Implement data import
    }
    
    private func clearAllData() {
        // TODO: Show confirmation dialog and implement data clearing
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self], inMemory: true)
}
