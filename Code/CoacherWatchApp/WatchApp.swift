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
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .modelContainer(for: [
                    SuccessNote.self,
                    CravingNote.self,
                    AudioRecording.self,
                    DailyEntry.self
                ])
        }
    }
}

