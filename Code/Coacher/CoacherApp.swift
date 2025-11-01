//
//  CoacherApp.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import WatchConnectivity

enum DeepLinkDestination {
    case needHelp
    case success
    case morningFocus
}

@main
struct CoacherApp: App {
    @StateObject private var celebrationManager = CelebrationManager()
    @StateObject private var reminderManager = ReminderManager.shared
    @StateObject private var notificationHandler = NotificationHandler.shared
    @StateObject private var hybridManager = HybridLLMManager()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @State private var deepLinkDestination: DeepLinkDestination?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyEntry.self,
            Achievement.self,
            LLMMessage.self,
            CravingNote.self,
            SuccessNote.self,
            EveningPrepItem.self,
            UserSettings.self,
            AudioRecording.self,
            EmotionalTakeoverNote.self,
            HabitHelperNote.self
        ])
        
        // Use App Group shared container
        let appGroupIdentifier = "group.com.coacher.shared"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ DEBUG: Failed to get App Group URL")
            fatalError("Could not get App Group URL")
        }
        print("📱 DEBUG: iOS using App Group: \(appGroupIdentifier)")
        print("📱 DEBUG: iOS App Group URL: \(groupURL)")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(appGroupIdentifier)
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("📱 DEBUG: iOS ModelContainer created successfully")
            return container
        } catch {
            print("❌ DEBUG: Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkDestination: $deepLinkDestination)
                .environmentObject(celebrationManager)
                .environmentObject(reminderManager)
                .environmentObject(notificationHandler)
                .environmentObject(hybridManager)
                .environmentObject(watchConnectivity)
                .onAppear {
                    setupNotifications()
                    startBackgroundModelLoading()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleDeepLink(_ url: URL) {
        switch url.scheme {
        case "coacher":
            switch url.host {
            case "needhelp":
                deepLinkDestination = .needHelp
            case "success":
                deepLinkDestination = .success
            case "morningfocus":
                deepLinkDestination = .morningFocus
            default:
                break
            }
        default:
            break
        }
    }
    
    private func setupNotifications() {
        Task {
            let granted = await reminderManager.requestNotificationPermissions()
            if granted {
                await reminderManager.scheduleReminders()
            }
        }
    }
    
private func startBackgroundModelLoading() {
    // Skip AI loading on simulator to prevent crashes
    #if targetEnvironment(simulator)
    print("📱 Running on simulator - skipping AI model loading for App Store screenshots")
    return
    #endif
    
    // Start loading the AI model in the background immediately
    // Users won't see this happening - it's completely invisible
    Task {
        await hybridManager.loadModel()
    }
}
}
