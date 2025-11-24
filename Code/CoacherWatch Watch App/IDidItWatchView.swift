//
//  IDidItWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData
import WatchKit
import WatchConnectivity

struct IDidItWatchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var watchConnectivity: WatchConnectivityManager
    @State private var showCelebration = false
    @State private var transcribedText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            if showCelebration {
                // Celebration view
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .symbolEffect(.bounce, value: showCelebration)
                    
                    Text("Way to go! 🌟")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Success recorded")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    // Haptic feedback
                    WKInterfaceDevice.current().play(.notification)
                    
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            } else {
                // Success capture interface
                VStack(spacing: 20) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Celebrate your success!")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    Text("Describe what you did")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Start Recording") {
                        presentDictation()
                    }
                    .buttonStyle(.borderedProminent)
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
                    self.saveAndCelebrate()
                }
            }
        )
    }
    
    private func saveAndCelebrate() {
        // Save with timestamp to indicate it was a voice recording
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let text = transcribedText.isEmpty ? "Success recorded via voice at \(dateFormatter.string(from: timestamp))" : transcribedText
        
        saveSuccessNote(text: text, audioURL: nil)
        
        withAnimation {
            showCelebration = true
        }
    }
    
    
    private func saveSuccessNote(text: String, audioURL: URL?) {
        let success = SuccessNote(
            type: .other,
            text: text,
            keptAudio: audioURL != nil,
            audioURL: audioURL
        )
        
        print("🔄 DEBUG: Inserting success note with text: '\(text)'")
        print("🔄 DEBUG: Success note ID: \(success.id)")
        print("🔄 DEBUG: Success note date: \(success.date)")
        
        modelContext.insert(success)
        
        do {
            try modelContext.save()
            print("✅ DEBUG: Successfully saved success note to modelContext")
            
            // Send to iOS via WatchConnectivity
            sendToiOS(successNote: success)
        } catch {
            print("❌ DEBUG: Failed to save success note: \(error)")
        }
    }
    
    private func sendToiOS(successNote: SuccessNote) {
        let message: [String: Any] = [
            "action": "successNote",
            "text": successNote.text,
            "date": successNote.date.timeIntervalSince1970,
            "type": successNote.type.rawValue
        ]
        
        watchConnectivity.sendMessageToiOS(message)
    }
}

#Preview {
    NavigationStack {
        IDidItWatchView()
    }
}
