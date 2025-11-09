//
//  SettingsView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData
import SafariServices

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
    @State private var showWidgetGuide = false
    @State private var safariURL: URL?
    @State private var showSafari = false
    
    var body: some View {
        NavigationView {
            List {
                remindersSection
                
                widgetSection
                
                personalizationSection
                
                gamificationSection
                
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
        .sheet(isPresented: $showSafari) {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
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
                            let accentColor: Color = colorScheme == .dark ? .white : .blue
                            
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(accentColor)
                            Text("How to Add Widget")
                                .foregroundColor(accentColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityLabel("How to add widget")
                    .accessibilityHint("Opens guide for adding home screen widget")
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
    
    private var aboutSection: some View {
        Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Privacy Policy") {
                        safariURL = URL(string: "https://www.lightertomorrow.com/public/privacy-policy.html")
                        showSafari = safariURL != nil
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .brandBlue)
                    
                    Button("Terms of Service") {
                        safariURL = URL(string: "https://www.lightertomorrow.com/public/terms-of-service.html")
                        showSafari = safariURL != nil
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .brandBlue)
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

// MARK: - Safari View

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Color.brandBlue)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self], inMemory: true)
}
