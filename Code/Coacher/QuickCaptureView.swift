//
//  QuickCaptureView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @State private var captureType: CaptureType = .voice
    @State private var textInput = ""
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var savedAudioURL: URL?
    
    enum CaptureType: String, CaseIterable, Identifiable {
        case voice = "Voice"
        case text = "Text"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .voice: return "mic.circle.fill"
            case .text: return "text.bubble.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with purpose
                VStack(spacing: 12) {
                    Text("Quick Support")
                        .font(.title2)
                        .bold()
                    
                    Text("Capture what's happening and get help choosing a healthier swap")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Capture Type Selector
                Picker("Capture Type", selection: $captureType) {
                    ForEach(CaptureType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Capture Interface
                if captureType == .voice {
                    VoiceCaptureView(
                        isRecording: $isRecording,
                        audioRecorder: $audioRecorder,
                        recordingTime: $recordingTime,
                        recordingTimer: $recordingTimer,
                        savedAudioURL: $savedAudioURL
                    )
                } else {
                    TextCaptureView(textInput: $textInput)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveCapture) {
                        Text("Save & Close")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(captureType == .voice && !isRecording && audioRecorder == nil)
                    
                    Button("Cancel", action: { dismiss() })
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quick Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func saveCapture() {
        if captureType == .voice {
            if let audioURL = savedAudioURL, recordingTime > 0 {
                // Save audio recording to database with meaningful transcription
                let transcription = "Quick voice capture - \(Date().formatted(date: .abbreviated, time: .shortened))"
                let recording = AudioRecording(
                    transcription: transcription,
                    duration: recordingTime
                )

                modelContext.insert(recording)

                do {
                    try modelContext.save()
                    
                    // Clean up the audio file after successful transcription
                    try FileManager.default.removeItem(at: audioURL)
                } catch {
                    print("Failed to save audio recording: \(error)")
                }
                
                // Record activity for milestone tracking
                celebrationManager.recordActivity()
            } else {
                // No recording or very short recording - don't save anything
                print("No meaningful recording to save")
            }
        } else if captureType == .text && !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Save text capture
            let recording = AudioRecording(
                transcription: textInput,
                duration: 0
            )
            
            modelContext.insert(recording)
            
            do {
                try modelContext.save()
                celebrationManager.recordActivity()
            } catch {
                print("Failed to save text recording: \(error)")
            }
        }
        
        dismiss()
    }
}

struct VoiceCaptureView: View {
    @Binding var isRecording: Bool
    @Binding var audioRecorder: AVAudioRecorder?
    @Binding var recordingTime: TimeInterval
    @Binding var recordingTimer: Timer?
    @Binding var savedAudioURL: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: toggleRecording) {
                VStack(spacing: 12) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(isRecording ? .red : .blue)
                    
                    Text(isRecording ? "Stop Recording" : "Voice Note")
                        .font(.headline)
                    
                    if isRecording {
                        Text("\(Int(recordingTime))s")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Tap to record")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isRecording ? .red : .blue, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            requestMicrophonePermission()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted, ready to record
                    } else {
                        // Permission denied
                    }
                }
            }
        } else {
            // Fallback for iOS 16 and earlier
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted, ready to record
                    } else {
                        // Permission denied
                    }
                }
            }
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            
            // Start timer for 20-second limit
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingTime += 1
                if recordingTime >= 20 {
                    stopRecording()
                }
            }
            

        } catch {

        }
    }
    
    private func stopRecording() {
        if let recorder = audioRecorder {
            savedAudioURL = recorder.url
            recorder.stop()
        }
        
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
        

    }
    

}

struct TextCaptureView: View {
    @Binding var textInput: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's happening?")
                .font(.headline)
            
            TextEditor(text: $textInput)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal, 4)
            
            Text("\(textInput.count) characters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    QuickCaptureView()
}
