//
//  IDidItWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import AVFoundation
import Speech
import SwiftData
import WatchKit

struct IDidItWatchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isRecording = false
    @State private var showCelebration = false
    @Environment(\.dismiss) var dismiss
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    
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
                // Recording interface
                VStack(spacing: 20) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    if isRecording {
                        Text("Recording...")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Button("Stop Recording") {
                            stopRecording()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else {
                        Text("Describe your success")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Start Recording") {
                            startRecording()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationTitle("I Did It")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startRecording() {
        // Request audio and speech permissions
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                Task { @MainActor in
                    isRecording = true
                    // Start recording logic
                }
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        // Stop recording and save as SuccessNote
        saveSuccessNote(text: "Voice recording", audioURL: nil)
        
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

