//
//  WatchApp.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData

@main
struct CoacherWatchApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SuccessNote.self,
            CravingNote.self,
            AudioRecording.self,
            DailyEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            // Use the same App Group container as the iOS app
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .modelContainer(sharedModelContainer)
        }
    }
}

