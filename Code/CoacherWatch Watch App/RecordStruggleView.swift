//
//  RecordStruggleView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData
import WatchKit
import WatchConnectivity

struct RecordStruggleView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    @State private var showEncouragement = false
    @State private var transcribedText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            if showEncouragement {
                // Encouragement view
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text(randomEncouragement)
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("Struggle recorded")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    WKInterfaceDevice.current().play(.notification)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            } else {
                // Recording interface
                VStack(spacing: 20) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("What's going on?")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("Describe what you're feeling")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Start Recording") {
                        presentDictation()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
    }
    
    private func presentDictation() {
        WKExtension.shared().rootInterfaceController?.presentTextInputController(
            withSuggestions: nil,
            allowedInputMode: .allowAnimatedEmoji,
            completion: { results in
                if let texts = results as? [String], let firstText = texts.first, !firstText.isEmpty {
                    self.transcribedText = firstText
                    self.saveAndEncourage()
                }
            }
        )
    }
    
    private func saveAndEncourage() {
        let text = transcribedText.isEmpty ? "Recorded struggle at \(Date().formatted(date: .omitted, time: .shortened))" : transcribedText
        saveCravingNote(text: text)
        
        withAnimation {
            showEncouragement = true
        }
    }
    
    private func saveCravingNote(text: String) {
        let craving = CravingNote(
            type: .other,
            text: text,
            keptAudio: false,
            audioURL: nil
        )
        
        modelContext.insert(craving)
        
        do {
            try modelContext.save()
            print("✅ Saved craving note: \(text)")
            sendToiOS(cravingNote: craving)
        } catch {
            print("❌ Failed to save craving note: \(error)")
        }
    }
    
    private func sendToiOS(cravingNote: CravingNote) {
        let message: [String: Any] = [
            "action": "cravingNote",
            "text": cravingNote.text,
            "date": cravingNote.date.timeIntervalSince1970,
            "type": cravingNote.type.rawValue
        ]
        watchConnectivity.sendMessageToiOS(message)
    }
    
    private let encouragements = [
        "You're doing great by acknowledging this 💪",
        "It's okay to struggle. You're not alone 🤗",
        "This feeling will pass 🌙",
        "You're stronger than this moment ✨",
        "One breath at a time 🌬️",
        "You can do hard things 💫"
    ]
    
    private var randomEncouragement: String {
        encouragements.randomElement() ?? encouragements[0]
    }
}

#Preview {
    NavigationStack {
        RecordStruggleView()
    }
}
