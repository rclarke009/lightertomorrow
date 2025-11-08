//
//  CareFirstMorningFocusSection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData
import AVKit
import WidgetKit

enum BreathingPhase {
    case inhale
    case exhale
}

struct CareFirstMorningFocusSection: View {
    @Binding var entry: DailyEntry
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @StateObject private var reminderManager = ReminderManager.shared
    
    // New care-first flow state
    @State private var currentStep = 0
    @State private var showingBreathingGuide = false
    @State private var isBreathingActive = false
    @State private var showingVideo = false
    @State private var videoPlayer: AVPlayer?
    @State private var videoLoopCount = 0
    @State private var videoObserver: NSObjectProtocol?
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var hasCompletedBreathingToday = false
    @State private var hasEverCompletedEndOfDay = false
    @State private var isInitialLoad = true
    @State private var breathCount = 0
    @State private var showInhaleText = false
    @State private var breathingCompleted = false
    @State private var hasCompletedMorningToday = false
    @State private var showFinalState = false
    @State private var showingCustomWhyInput = false
    
    let onCelebrationTrigger: (String, String) -> Void = { _, _ in }
    
    private let whyOptions = [
        "Feel healthy and energetic",
        "Be there for my family",
        "Live to see my grandchildren",
        "Feel confident in my body",
        "Set a good example",
        "Have steady energy"
    ]
    
    private var breathingPhaseText: String {
        switch breathingPhase {
        case .inhale:
            return "Deep Breath In"
        case .exhale:
            return "Voo Sound Out"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
        // Progress indicator
        ProgressView(value: Double(currentStep), total: 7)
                .progressViewStyle(LinearProgressViewStyle(tint: colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue))
                .accessibilityLabel("Morning focus progress")
                .accessibilityValue("Step \(currentStep) of 7")
                .scaleEffect(x: 1, y: 0.8)
            
            // Step content
            switch currentStep {
            case 0:
                resetStateStep
            case 1:
                whyStep
            case 2:
                identityStep
            case 3:
                focusStep
            case 4:
                stressResponseStep
            case 5:
                visualStep
            case 6:
                completionStep
            case 7:
                summaryStep
            default:
                EmptyView()
            }
            
            // Navigation buttons (hidden on completion and summary steps)
            if currentStep != 6 && currentStep != 7 {
                HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(nextButtonTitle) {
                    handleNextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(showFinalState ? .blue : (colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue))
                .disabled(!canProceed)
                .foregroundColor(showFinalState ? .white : nil)
                .accessibilityLabel("Continue to next step")
                .accessibilityHint("Advances to step \(currentStep + 1) of 7")
            }
            .padding(.top, 8)
            }
        }
        .onAppear {
            // Load saved data if available
            loadSavedData()
            
            // Check if breathing was completed today
            checkBreathingCompletionToday()
            
            // Check if morning routine was completed today
            checkMorningCompletionToday()
            
            // Check if user has ever completed end-of-day check-in
            checkEndOfDayCompletion()
            
            // Mark initial load as complete after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitialLoad = false
            }
        }
        .onDisappear {
            // Clean up video observer when view disappears
            if let observer = videoObserver {
                NotificationCenter.default.removeObserver(observer)
                videoObserver = nil
            }
        }
    }
    
    // MARK: - Step Views
    
    private var whyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("2")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Why Does This Matter?")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Connect to your deeper reason for making healthy choices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                // Quick-tap option chips
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(whyOptions, id: \.self) { option in
                        Button(option) {
                            entry.whyThisMatters = option
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(entry.whyThisMatters == option ? Color.blue : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(entry.whyThisMatters == option ? .white : .primary)
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Custom input button
                Button("Custom") {
                    showingCustomWhyInput = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(colorScheme == .dark ? .white : .blue)
                .frame(maxWidth: .infinity)
                
                // Display selected text
                if !entry.whyThisMatters.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your why:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I want to")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text(entry.whyThisMatters)
                                .font(.body)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )
                        
                        Text("How does this feel today? Tap to edit if needed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCustomWhyInput) {
            CustomWhyInputView(whyThisMatters: $entry.whyThisMatters)
        }
    }
    
    private var resetStateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                        Text("Begin your day with calm.")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Try the Voo breath technique: Find a comfortable position, take a deep breath in, then exhale with a deep 'voo' sound from your belly. Feel the vibration and repeat for a few minutes. If you need a quiet option, follow the same pattern silently. Use either guide to help with timing your breaths")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                if showingVideo {
                    // Embedded video player
                    if let player = videoPlayer {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .clipped()
                            .onAppear {
                                setupVideoLooping()
                                player.play()
                            }
                    }
                    
                    VStack(spacing: 8) {
                        Text("Loop \(videoLoopCount)/3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Close Video") {
                            closeVideo()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.helpButtonBlue)
                    }
                    
                } else if isBreathingActive {
                    VStack(spacing: 20) {
                        // Breathing ring animation
                        BreathingRingView(phase: breathingPhase)
                            .frame(height: 120)
                        
                        // Always maintain consistent height with placeholder
                        ZStack {
                            // Invisible placeholder to maintain consistent height
                            Text("Quick Inhale")
                                .font(.title2)
                                .fontWeight(.medium)
                                .opacity(0)
                                .accessibilityHidden(true)
                            
                            // Actual text content
                            if breathingCompleted {
                                Text("Great job!")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.5), value: breathingCompleted)
                            } else if showInhaleText && breathingPhase == .inhale {
                                Text("Deep Breath In")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3), value: showInhaleText)
                            } else if breathingPhase == .exhale {
                                Text("Voo Sound Out")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3), value: breathingPhase)
                            }
                        }
                        
                        
                        Button("Stop") {
                            stopBreathing()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.blue)
                    }
                } else {
                    VStack(spacing: 16) {
                        // Breathing icon
                        Image(systemName: "wind")
                            .font(.system(size: 40))
                            .foregroundColor(colorScheme == .dark ? .white : .helpButtonBlue)
                        
                        HStack(spacing: 16) {
                            Button("Start Voo Breathing") {
                                startBreathing()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .accessibilityLabel("Start Voo breathing exercise")
                            .accessibilityHint("Begins guided breathing exercise with audio cues")
                            .accessibilityAddTraits(.startsMediaSession)
                            .controlSize(.large)
                            
                            Button("Play Breathing Guide") {
                                playBreathingVideo()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .controlSize(.large)
                            .accessibilityLabel("Play breathing guide video")
                            .accessibilityHint("Plays guided breathing visualization")
                            .accessibilityAddTraits(.startsMediaSession)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("3")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Remind Yourself Who You're Becoming")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Complete this thought:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Today I want to be the kind of person who…")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .helpButtonBlue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: Binding(
                        get: { entry.identityStatement ?? "" },
                        set: { entry.identityStatement = $0.isEmpty ? nil : $0 }
                    ), selectAllOnTap: true)
                        .frame(minHeight: 80)
                        .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                        .font(.subheadline)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .padding(0)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                        )
                        .accessibilityLabel("Who You're Becoming")
                        .accessibilityHint("Complete the thought: Today I want to be the kind of person who…")
                    
                    // Show placeholder text only when field is empty
                    if entry.identityStatement?.isEmpty != false {
                        Text("Example: \"Today I want to be the kind of person who takes care of my body and stays calm.\"")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                
                // Show helpful text below the field
                if entry.identityStatement?.isEmpty != false {
                    Text("How does this feel today? Tap to edit if needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    private var focusStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("4")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Set Today's Focus")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Complete this sentence:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Today I will care for myself by...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .helpButtonBlue)
                
                Text("What feels right for today specifically?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            ZStack(alignment: .topLeading) {
                SelectableTextEditor(text: $entry.todaysFocus, selectAllOnTap: true)
                    .frame(minHeight: 80)
                    .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                    .font(.subheadline)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .padding(0)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                    )
                    .accessibilityLabel("Today's Focus")
                    .accessibilityHint("Complete the sentence: Today I will care for myself by...")
                
                if entry.todaysFocus.isEmpty {
                    Text("Example: \"moving gently and pausing to breathe before meals\"")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var stressResponseStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("5")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Plan Your Response")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("When a difficult moment hits today — stress, boredom, or anything else — how will you care for yourself first?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("If I feel off or pulled off-track, I will…")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("What feels helpful for today's challenges?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                
                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: $entry.stressResponse, selectAllOnTap: true)
                        .frame(minHeight: 60)
                        .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                        .font(.subheadline)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .padding(0)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                        )
                        .accessibilityLabel("Challenge Response")
                        .accessibilityHint("What will you do when a difficult moment hits?")
                    
                    if entry.stressResponse.isEmpty {
                        Text("Examples: dance to one song, text a friend, go stand in the sun for 3 minutes")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                
                Text("(If I still want something to eat afterward, I'll have __________.)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                
                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: $entry.optionalSupportiveSnack, selectAllOnTap: true)
                        .frame(minHeight: 40)
                        .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                        .font(.subheadline)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .padding(0)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                        )
                        .accessibilityLabel("Optional Supportive Snack")
                        .accessibilityHint("Optional: what supportive snack would you have?")
                    
                    if entry.optionalSupportiveSnack.isEmpty {
                        Text("Optional: a piece of fruit, a handful of nuts, etc.")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
    
    private var visualStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("6")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Finish With a Quick Visual")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Take a deep breath and picture yourself calmly following your plan.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(colorScheme == .dark ? .white : .helpButtonBlue)
                
                Text("You're ready to care for yourself today.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var nextButtonTitle: String {
        switch currentStep {
        case 0: return "Next"
        case 1, 2, 3, 4: return "Next"
        case 5: return "See My Plan"
        default: return "Next"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: 
            // Always enable "Done with Breathing" button - users may have already meditated
            return true
        case 1: return !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return !(entry.identityStatement?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case 3: return !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: return !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 5: return true
        default: return false
        }
    }
    
    // MARK: - Actions
    
    private func handleNextStep() {
        if currentStep == 0 {
            // Stop any active breathing and move to next step
            if isBreathingActive {
                stopBreathing()
            }
            
            // Mark breathing as completed today
            if !hasCompletedBreathingToday {
                hasCompletedBreathingToday = true
                saveBreathingCompletionToday()
            }
            
            // Reset animation states when moving to next step
            showFinalState = false
            
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else if currentStep < 5 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else if currentStep == 5 {
            // Complete morning flow and go to completion step
            completeMorningFlow()
        } else if currentStep == 6 {
            // Move to summary step
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else if currentStep == 7 {
            // Complete morning flow
            completeMorningFlow()
        }
    }
    
    private func startBreathing() {
        isBreathingActive = true
        breathingPhase = .inhale
        breathCount = 0  // Reset breath count
        showInhaleText = false  // Reset text state
        breathingCompleted = false  // Reset completion state
        
        // Start the breathing cycle
        startBreathingCycle()
    }
    
    private func startBreathingCycle() {
        // Show "Quick Inhale" text immediately
        showInhaleText = true
        
        // First quick inhale for 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if isBreathingActive {
                // Hide "Quick Inhale" text
                showInhaleText = false
                
                // Wait 0.5 seconds before showing text again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isBreathingActive {
                        // Show "Quick Inhale" text again for second inhale
                        showInhaleText = true
                        
                        // Second quick inhale for 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if isBreathingActive {
                                // Hide "Quick Inhale" text and switch to exhale
                                showInhaleText = false
                                breathingPhase = .exhale
                                
                                // Long exhale for 6 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                    if isBreathingActive {
                                        // Increment breath count
                                        breathCount += 1
                                        
                                        if breathCount >= 3 {
                                            // Stop after 3 complete breaths
                                            stopBreathing()
                                        } else {
                                            // Cycle repeats - reset to inhale
                                            breathingPhase = .inhale
                                            startBreathingCycle()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func stopBreathing() {
        isBreathingActive = false
        breathingPhase = .inhale
        showInhaleText = false  // Reset text state
        breathingCompleted = true  // Show completion message
        
        // After 0.5 seconds, show final state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFinalState = true
        }
    }
    
    private func playBreathingVideo() {
        guard let videoURL = Bundle.main.url(forResource: "breathing", withExtension: "mp4") else {
            print("Breathing video not found in bundle")
            return
        }
        
        videoPlayer = AVPlayer(url: videoURL)
        videoLoopCount = 0
        showingVideo = true
    }
    
    private func setupVideoLooping() {
        guard let player = videoPlayer else { return }
        
        // Remove any existing observer
        if let observer = videoObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add observer for when video finishes
        videoObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            videoLoopCount += 1
            
            if videoLoopCount < 3 {
                // Add a brief pause before restarting video for next loop
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Restart video for next loop (3 loops = 3 complete breathing cycles)
                    player.seek(to: .zero)
                    player.play()
                }
            } else {
                // After 3 loops, just close video (don't auto-start breathing)
                closeVideo()
            }
        }
    }
    
    private func closeVideo() {
        showingVideo = false
        videoPlayer?.pause()
        
        // Remove observer
        if let observer = videoObserver {
            NotificationCenter.default.removeObserver(observer)
            videoObserver = nil
        }
        
        // Mark breathing as completed (same as stopBreathing)
        breathingCompleted = true
            
        // Save breathing completion
        UserDefaults.standard.set(Date(), forKey: "breathingCompletedDate")
    }
    
    private func completeMorningFlow() {
        // Save data
        saveData()
        
        // Mark morning routine as completed today
        hasCompletedMorningToday = true
        UserDefaults.standard.set(Date(), forKey: "morningCompletedDate")
        
        // Write widget data to UserDefaults for real-time widget updates
        let userDefaults = UserDefaults(suiteName: "group.com.coacher.shared") ?? UserDefaults.standard
        userDefaults.set(Date(), forKey: "morningCompletedDate")
        userDefaults.set(entry.whyThisMatters, forKey: "morningWhy")
        userDefaults.set(entry.identityStatement ?? "", forKey: "morningIdentity")
        userDefaults.set(entry.todaysFocus, forKey: "morningFocus")
        userDefaults.set(entry.stressResponse, forKey: "morningStressResponse")
        
        // Reload widget to show updated data
        WidgetCenter.shared.reloadAllTimelines()
        
        // Trigger celebration
        celebrationManager.triggerCelebration(for: .morningFlowCompleted)
        
        // Cancel morning reminder
        reminderManager.cancelMorningReminder()
        
        // Go to completion screen instead of resetting
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 6
        }
    }
    
    private func checkBreathingCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "breathingCompletedDate") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            hasCompletedBreathingToday = true
            print("🎉 DEBUG: Breathing already completed today at \(savedDate)")
        } else {
            hasCompletedBreathingToday = false
            print("🎉 DEBUG: No breathing completion found for today")
        }
    }
    
    private func saveBreathingCompletionToday() {
        UserDefaults.standard.set(Date(), forKey: "breathingCompletedDate")
    }
    
    // DEBUG: Reset breathing completion for testing
    private func resetBreathingCompletion() {
        UserDefaults.standard.removeObject(forKey: "breathingCompletedDate")
        hasCompletedBreathingToday = false
        print("🎉 DEBUG: Breathing completion reset for testing")
    }
    
    private func checkEndOfDayCompletion() {
        hasEverCompletedEndOfDay = UserDefaults.standard.bool(forKey: "hasEverCompletedEndOfDay")
        print("🎉 DEBUG: Has ever completed end-of-day: \(hasEverCompletedEndOfDay)")
    }
    
    private func checkMorningCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "morningCompletedDate") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            hasCompletedMorningToday = true
            print("🎉 DEBUG: Morning routine already completed today at \(savedDate)")
        } else {
            hasCompletedMorningToday = false
            print("🎉 DEBUG: No morning completion found for today")
        }
    }
    
    private func checkForCelebration() {
        // Celebrations are now only triggered when the entire morning flow is completed
        // in completeMorningFlow() - no premature celebrations during typing
    }
    
    private func loadSavedData() {
        // Load yesterday's data as starting points for stable fields
        loadYesterdayData()
        
        // Load saved data if available (for current session)
        if entry.whyThisMatters.isEmpty {
            let saved = UserDefaults.standard.string(forKey: "savedWhyThisMatters")
            if let saved = saved, !saved.isEmpty {
                entry.whyThisMatters = saved
            }
        }
        
        if entry.identityStatement?.isEmpty != false {
            let saved = UserDefaults.standard.string(forKey: "savedIdentityStatement")
            if let saved = saved, !saved.isEmpty {
                entry.identityStatement = saved
            }
        }
        
        // Today's focus and stress response stay fresh - no pre-filling
    }
    
    private func loadYesterdayData() {
        // Get yesterday's entry to pre-fill stable fields
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let yesterdayEnd = Calendar.current.date(byAdding: .day, value: 1, to: yesterdayStart) ?? Date()
        
        // Query for yesterday's entry
        let request = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= yesterdayStart && entry.date < yesterdayEnd
            }
        )
        
        do {
            let yesterdayEntries = try context.fetch(request)
            if let yesterdayEntry = yesterdayEntries.first {
                // Pre-fill stable fields with yesterday's answers
                if !yesterdayEntry.whyThisMatters.isEmpty && entry.whyThisMatters.isEmpty {
                    entry.whyThisMatters = yesterdayEntry.whyThisMatters
                }
                
                // Don't pre-fill identity statement - let it stay empty so user can start fresh
                // The placeholder text will show the example instead
            }
        } catch {
            print("Failed to load yesterday's data: \(error)")
        }
    }
    
    private func saveData() {
        // Save why this matters
        if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(entry.whyThisMatters, forKey: "savedWhyThisMatters")
        }
        
        // Save identity statement
        if let identityStatement = entry.identityStatement, !identityStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(identityStatement, forKey: "savedIdentityStatement")
        }
        
        // Save focus
        if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(entry.todaysFocus, forKey: "savedTodaysFocus")
        }
        
        // Save stress response
        if !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(entry.stressResponse, forKey: "savedStressResponse")
        }
    }
    private var completionStep: some View {
        VStack(spacing: 24) {
            // Header with checkmark
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                
                Text("Morning Focus Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("You're ready to win the day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Full plan summary as clean list
            VStack(spacing: 0) {
                // Why This Matters
                if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Why This Matters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I want to")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text(entry.whyThisMatters)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   (entry.identityStatement?.isEmpty == false || !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Identity Statement
                if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("I Am Someone Who...")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(identity)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   (!entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Today's Focus
                if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Today's Focus")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(entry.todaysFocus)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Stress Response
                if !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("If Stressed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(entry.stressResponse)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Restart button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 0
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Restart Morning Focus")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private var summaryStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                
                Text("Morning Focus Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("You're ready to win the day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Full plan summary as clean list
            VStack(spacing: 0) {
                // Why This Matters
                if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Why This Matters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I want to")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text(entry.whyThisMatters)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if !entry.whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   (entry.identityStatement?.isEmpty == false || !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Identity Statement
                if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("I Am Someone Who...")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(identity)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if let identity = entry.identityStatement, !identity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   (!entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Today's Focus
                if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Today's Focus")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(entry.todaysFocus)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                
                // Divider
                if !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                   !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Stress Response
                if !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("If Stressed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text(entry.stressResponse)
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Restart button (immediate action, no confirmation)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 0
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Restart Morning Focus")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var encouragementMessage: String {
        let messages = [
            "Carry this focus with you today.",
            "One mindful morning at a time.",
            "You've set yourself up for success.",
            "Today's foundation is strong.",
            "Your future self is grateful."
        ]
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Breathing Ring View

struct BreathingRingView: View {
    let phase: BreathingPhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0.3
    @State private var secondRingScale: CGFloat = 0.3
    @State private var secondRingOpacity: Double = 0.3
    @State private var exhaleRingScale: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let circleColor = colorScheme == .dark ? Color.white : Color.helpButtonBlue
                
                // Background circle
                Circle()
                    .fill(circleColor.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                // First inhale ring
                Circle()
                    .stroke(circleColor, lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                
                // Second inhale ring (for the second quick inhale)
                Circle()
                    .stroke(circleColor, lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(secondRingScale)
                    .opacity(secondRingOpacity)
                
                // Exhale ring (larger, for the long exhale)
                Circle()
                    .stroke(circleColor.opacity(0.6), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(exhaleRingScale)
                    .opacity(phase == .exhale ? 0.8 : 0.0)
                
                // Center dot
                Circle()
                    .fill(circleColor)
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startRingAnimation()
        }
        .onChange(of: phase) { _, _ in
            startRingAnimation()
        }
    }
    
    private func startRingAnimation() {
        switch phase {
        case .inhale:
            // First quick inhale - expand ring
            withAnimation(.easeIn(duration: 2.0)) {
                ringScale = 1.2
                ringOpacity = 0.8
            }
            
            // After first inhale, start second inhale
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if phase == .inhale {
                    withAnimation(.easeIn(duration: 2.0)) {
                        secondRingScale = 1.1
                        secondRingOpacity = 0.6
                    }
                }
            }
            
        case .exhale:
            // Long exhale - contract rings and show exhale ring
            withAnimation(.easeOut(duration: 6.0)) {
                ringScale = 0.3
                ringOpacity = 0.1
                secondRingScale = 0.3
                secondRingOpacity = 0.1
                exhaleRingScale = 0.5
            }
        }
    }
}


// SelectableTextEditor is already defined in MorningFocusSection.swift

extension CareFirstMorningFocusSection {
    private func sparkleOffset(for index: Int) -> (x: CGFloat, y: CGFloat) {
        switch index {
        case 0: return (-25, -8)   // Top left
        case 1: return (25, -8)    // Top right
        case 2: return (-25, 8)    // Bottom left
        case 3: return (25, 8)     // Bottom right
        default: return (0, 0)
        }
    }
}

struct CustomWhyInputView: View {
    @Binding var whyThisMatters: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var textInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink)
                        .accessibilityLabel("Why this matters")
                        .accessibilityHidden(false)
                    
                    Text("Why Does This Matter?")
                        .font(.title2)
                        .bold()
                    
                    Text("What's your deeper reason for making healthy choices?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Text Input
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your why:")
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
                        .accessibilityLabel("Your why")
                        .accessibilityHint("Describe your deeper reason for making healthy choices")
                    
                    Text("Examples: I want to feel healthy and energetic, or I want to live to see my grandchildren grow up...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        whyThisMatters = textInput
                        dismiss()
                    }) {
                        Text("Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Cancel", action: { dismiss() })
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Custom Why")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                textInput = whyThisMatters
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ScrollView {
        CareFirstMorningFocusSection(entry: .constant(DailyEntry()))
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
