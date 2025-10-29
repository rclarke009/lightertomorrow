//
//  WatchApp.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct CoacherWatchApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
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
        print("⌚️ DEBUG: Watch using App Group: \(appGroupIdentifier)")
        print("⌚️ DEBUG: Watch App Group URL: \(groupURL)")
        
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
            print("⌚️ DEBUG: Watch ModelContainer created successfully")
            return container
        } catch {
            print("❌ DEBUG: Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .modelContainer(sharedModelContainer)
                .environmentObject(watchConnectivity)
        }
    }
}

