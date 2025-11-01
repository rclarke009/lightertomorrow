//
//  SuccessCaptureView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import WidgetKit
import Speech

struct SuccessCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedType: SuccessType? = .choice
    @State private var showingTextCapture = false
    @State private var showingAudioCapture = false
    @State private var capturedText = ""
    @State private var capturedAudioURL: URL?
    @State private var keptAudio = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Success star")
                        .accessibilityHidden(false)
                    
                    Text("I Did Great!")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("What made this moment special?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
                
                // Category Selection
                VStack(spacing: 16) {
                    ForEach(SuccessType.allCases) { type in
                        SuccessCategoryButton(type: type, isSelected: selectedType == type) {
                            selectedType = type
                        }
                    }
                }
                
                Spacer()
                
                // Capture Options
                if selectedType != nil {
                    VStack(spacing: 8) {
                        Text("How would you like to capture this moment?")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            // Text Capture Button
                            Button(action: { showingTextCapture = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "text.bubble.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.green)
                                    
                                    Text("Text Note")
                                        .font(.headline)
                                    
                                    Text("Type it out")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.green, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Text Note")
                            .accessibilityHint("Capture your success by typing text")
                            
                            // Audio Capture Button
                            Button(action: { showingAudioCapture = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "mic.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.blue)
                                    
                                    Text("Voice Note")
                                        .font(.headline)
                                    
                                    Text("Tap to record")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.blue, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Record voice note")
                            .accessibilityHint("Starts audio recording for 20 seconds")
                            .accessibilityAddTraits(.startsMediaSession)
                        }
                    }
                }
                
                Spacer()
                }
            }
            .scrollIndicators(.hidden)
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
        .sheet(isPresented: $showingTextCapture) {
            SuccessTextCaptureView(
                type: selectedType ?? .choice,
                onSave: { text in
                    capturedText = text
                    saveSuccess()
                }
            )
        }
        .sheet(isPresented: $showingAudioCapture) {
            SuccessAudioCaptureView(
                type: selectedType ?? .choice,
                onSave: { audioURL, keptAudio, transcribedText in
                    capturedAudioURL = audioURL
                    self.keptAudio = keptAudio
                    capturedText = transcribedText
                    saveSuccess()
                }
            )
        }
    }
    
    private func saveSuccess() {
        guard let type = selectedType else { return }
        
        let successNote = SuccessNote(
            type: type,
            text: capturedText,
            keptAudio: keptAudio,
            audioURL: capturedAudioURL
        )
        
        // Save on main queue to prevent SwiftData threading issues
        DispatchQueue.main.async {
            self.context.insert(successNote)
            
            do {
                try self.context.save()
                
                // Update widget data for real-time widget updates
                let userDefaults = UserDefaults(suiteName: "group.com.coacher.shared") ?? UserDefaults.standard
                let currentCount = userDefaults.integer(forKey: "successNotesToday")
                userDefaults.set(currentCount + 1, forKey: "successNotesToday")
                
                // Reload widget to show updated success count
                WidgetCenter.shared.reloadAllTimelines()
                
                // Trigger celebration
                if self.celebrationManager.shouldCelebrate() {
                    self.celebrationManager.recordActivity()
                    // The celebration will be handled by the parent view
                }
                
                self.dismiss()
            } catch {
                print("Failed to save success note: \(error)")
                // Could add user-facing error message here if needed
            }
        }
    }
}

struct SuccessCategoryButton: View {
    let type: SuccessType
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : (colorScheme == .dark ? Color.brightBlue : .primary))
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color : (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6)))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(type.displayName)
        .accessibilityHint(type.description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

struct SuccessTextCaptureView: View {
    let type: SuccessType
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var text = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(type.color)
                    
                    Text("Tell us about your \(type.displayName.lowercased())")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                TextEditor(text: $text)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
                    .accessibilityLabel("Text input")
                    .accessibilityHint("Enter details about your \(type.displayName.lowercased())")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Capture Success")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SuccessAudioCaptureView: View {
    let type: SuccessType
    let onSave: (URL?, Bool, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var transcribedText = ""
    @State private var showingTextEditor = false
    @State private var savedAudioURL: URL?
    @State private var showRecordingError = false
    @State private var hasRecorded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(type.color)
                    
                    Text("Record your \(type.displayName.lowercased())")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if !hasRecorded {
                    // Recording Interface
                    VStack(spacing: 16) {
                        // Recording Button
                        Button(action: toggleRecording) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(isRecording ? .red : .blue)
                                .scaleEffect(isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        }
                        
                        Text(isRecording ? "Recording... Tap to stop" : "Tap to start recording")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Show captured content
                    VStack(spacing: 16) {
                        Text("Your Success:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(transcribedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        
                        Button("Edit Text") {
                            showingTextEditor = true
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        
                        Button("Save Success") {
                            onSave(savedAudioURL, true, transcribedText)
                            dismiss()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.blue : Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Record Success")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        stopRecording()
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
        .onAppear {
            requestMicrophonePermission()
        }
        .onDisappear {
            stopRecording()
        }
        .sheet(isPresented: $showingTextEditor) {
            SuccessTextEditorView(text: $transcribedText)
        }
        .alert("Recording Issue", isPresented: $showRecordingError) {
            Button("Try Again") {
                // Reset recording state
                transcribedText = ""
                savedAudioURL = nil
                hasRecorded = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We couldn't process your recording. You can try recording again.")
                .foregroundColor(colorScheme == .dark ? .white : .primary)
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
            let audioFilename = documentsPath.appendingPathComponent("success_\(UUID().uuidString).m4a")
            
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
            
            // Announce recording start to VoiceOver users
            UIAccessibility.post(notification: .announcement, argument: "Recording started")
            
            // Start timer for 20-second limit
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                recordingTime += 1
                if recordingTime >= 20 {
                    stopRecording()
                }
            }
            
        } catch {
            print("Failed to start recording: \(error)")
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
        
        // Announce recording completion to VoiceOver users
        UIAccessibility.post(notification: .announcement, argument: "Recording complete")
        
        // Transcribe the recorded audio
        if let audioURL = savedAudioURL {
            transcribeAudio(from: audioURL)
        }
    }
    
    private func transcribeAudio(from url: URL) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognition not available")
            DispatchQueue.main.async {
                self.showRecordingError = true
            }
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Speech recognition error: \(error)")
                    if self.transcribedText.isEmpty {
                        self.showRecordingError = true
                    }
                } else if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    print("Transcription completed: \(transcription)")
                    self.transcribedText = transcription
                    self.hasRecorded = true
                }
            }
        }
    }
}


struct SuccessTextEditorView: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextEditor(text: $text)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SuccessCaptureView()
        .modelContainer(for: [SuccessNote.self], inMemory: true)
}
