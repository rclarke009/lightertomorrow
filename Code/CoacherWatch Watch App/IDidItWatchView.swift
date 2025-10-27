//
//  IDidItWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData
import WatchKit

struct IDidItWatchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showCelebration = false
    @State private var isRecording = false
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
            } else if isRecording {
                // Recording interface
                VStack(spacing: 20) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Recording...")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Speak about your success")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Stop Recording") {
                        isRecording = false
                        saveAndCelebrate()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .onAppear {
                    startVoiceRecording()
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
                        isRecording = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func startVoiceRecording() {
        // Allow 20 seconds of recording time
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if isRecording {
                isRecording = false
                // Save with a placeholder text indicating it's a voice recording
                saveAndCelebrate()
            }
        }
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
        
        modelContext.insert(success)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save success note: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        IDidItWatchView()
    }
}
