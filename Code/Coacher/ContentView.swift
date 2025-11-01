//
//  ContentView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject private var hybridManager: HybridLLMManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showNeedHelp = false
    @State private var showSuccessCapture = false
    @Environment(\.colorScheme) private var colorScheme
    @Binding var deepLinkDestination: DeepLinkDestination?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "calendar") }
                .tag(0)
            CoachView()
                .environmentObject(hybridManager)
                .tabItem { Label("Coach", systemImage: "message") }
                .tag(1)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .accentColor(.leafGreen)
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: selectedTab) { _, _ in
            updateTabBarAppearance()
        }
        .onChange(of: colorScheme) { _, _ in
            updateTabBarAppearance()
        }
        .onReceive(notificationHandler.$shouldShowTab) { tabIndex in
            if tabIndex != 0 { // Only change if it's not the default value
                selectedTab = tabIndex
                notificationHandler.shouldShowTab = 0 // Reset
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchSuccessNoteReceived"))) { notification in
            handleWatchSuccessNote(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchCravingNoteReceived"))) { notification in
            handleWatchCravingNote(notification)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showNeedHelp) {
            NeedHelpView()
        }
        .sheet(isPresented: $showSuccessCapture) {
            SuccessCaptureView()
        }
        .onChange(of: deepLinkDestination) { _, destination in
            switch destination {
            case .needHelp:
                showNeedHelp = true
                deepLinkDestination = nil
            case .success:
                showSuccessCapture = true
                deepLinkDestination = nil
            case .morningFocus:
                selectedTab = 0 // Switch to Today tab
                deepLinkDestination = nil
            case .none:
                break
            }
        }
    }
    
    private func updateTabBarAppearance() {
        DispatchQueue.main.async {
            let appearance = UITabBarAppearance()
            
            // Use app background colors for all tabs
            if self.colorScheme == .light {
                // Light mode: Light blue with transparency
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.85) // Light blue with 85% opacity
            } else {
                // Dark mode: Black with transparency
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.85)
            }
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Force update all tab bars
            for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
                if let tabBarController = window.rootViewController as? UITabBarController {
                    tabBarController.tabBar.standardAppearance = appearance
                    tabBarController.tabBar.scrollEdgeAppearance = appearance
                }
            }
        }
    }
    
    private func handleWatchSuccessNote(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let text = userInfo["text"] as? String,
              let date = userInfo["date"] as? Date,
              let typeRaw = userInfo["type"] as? String else {
            print("❌ Invalid watch success note data")
            return
        }
        
        // Create success note from watch data
        let success = SuccessNote(
            type: SuccessType(rawValue: typeRaw) ?? .other,
            text: text,
            keptAudio: false,
            audioURL: nil
        )
        success.date = date // Override date from watch
        
        modelContext.insert(success)
        
        do {
            try modelContext.save()
            print("✅ Saved watch success note to iOS: \(text)")
        } catch {
            print("❌ Failed to save watch success note: \(error)")
        }
    }
    
    private func handleWatchCravingNote(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let text = userInfo["text"] as? String,
              let date = userInfo["date"] as? Date,
              let typeRaw = userInfo["type"] as? String else {
            print("❌ Invalid watch craving note data")
            return
        }
        
        // Create craving note from watch data
        let craving = CravingNote(
            type: CravingType(rawValue: typeRaw) ?? .other,
            text: text,
            keptAudio: false,
            audioURL: nil
        )
        craving.date = date // Override date from watch
        
        modelContext.insert(craving)
        
        do {
            try modelContext.save()
            print("✅ Saved watch craving note to iOS: \(text)")
        } catch {
            print("❌ Failed to save watch craving note: \(error)")
        }
    }
}

#Preview {
    ContentView(deepLinkDestination: .constant(nil))
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self, CravingNote.self, EveningPrepItem.self, UserSettings.self, AudioRecording.self], inMemory: true)
}
