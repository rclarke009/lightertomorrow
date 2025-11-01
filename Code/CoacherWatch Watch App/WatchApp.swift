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
        
        // One-time migration: Delete existing database files to start fresh (schema changed - added conversationId)
        // Note: iOS app also does this, but doing it here ensures watch app works independently
        // This only runs once on first launch after the schema change
        let migrationKey = "hasMigratedToConversationIdSchema"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            let databaseFiles = ["default.store", "default.store-shm", "default.store-wal"]
            var deletedAny = false
            for fileName in databaseFiles {
                let fileURL = groupURL.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                        print("🗑️ DEBUG: Watch deleted old database file: \(fileName)")
                        deletedAny = true
                    } catch {
                        print("⚠️ DEBUG: Watch failed to delete \(fileName): \(error)")
                    }
                }
            }
            if deletedAny {
                UserDefaults.standard.set(true, forKey: migrationKey)
                print("✅ DEBUG: Watch migration complete - database reset for conversationId schema")
            }
        }
        
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

