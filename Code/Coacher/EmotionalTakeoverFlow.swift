//
//  EmotionalTakeoverFlow.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import AVFoundation
import AVKit

struct EmotionalTakeoverFlow: View {
    let onComplete: (EmotionalTakeoverNote) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: EmotionalStep = .nameIt
    @State private var bodySensation = ""
    @State private var partNeed = ""
    @State private var nextTimePlan = ""
    @State private var comfortableThings = ["", "", ""]
    @State private var audioPlayer: AVAudioPlayer?
    
    enum EmotionalStep: Int, CaseIterable {
        case nameIt = 0, noticeBody = 1, completeStressCycle = 2, pendulate = 3, soothePart = 4, rehearsePlan = 5
    }
    
    private var currentStepName: String {
        switch currentStep {
        case .nameIt: return "Name It"
        case .noticeBody: return "Notice Body"
        case .completeStressCycle: return "Complete Stress Cycle"
        case .pendulate: return "Pendulate"
        case .soothePart: return "Soothe Part"
        case .rehearsePlan: return "Rehearse Plan"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep.rawValue), total: Double(EmotionalStep.allCases.count - 1))
                    .padding(.horizontal)
                    .accessibilityLabel("Emotional support progress")
                    .accessibilityValue("Step \(currentStep.rawValue + 1) of \(EmotionalStep.allCases.count): \(currentStepName)")
                
                // Content based on current step
                switch currentStep {
                case .nameIt:
                    NameItStep {
                        currentStep = .noticeBody
                    }
                case .noticeBody:
                    NoticeBodyStep(bodySensation: $bodySensation) {
                        currentStep = .completeStressCycle
                    }
                case .completeStressCycle:
                    CompleteStressCycleStep {
                        currentStep = .pendulate
                    }
                case .pendulate:
                    PendulateStep(comfortableThings: $comfortableThings) {
                        currentStep = .soothePart
                    }
                case .soothePart:
                    SoothePartStep(partNeed: $partNeed) {
                        currentStep = .rehearsePlan
                    }
                case .rehearsePlan:
                    RehearsePlanStep(nextTimePlan: $nextTimePlan) {
                        completeFlow()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep != .nameIt {
                        Button("Back") {
                            if let currentIndex = EmotionalStep.allCases.firstIndex(of: currentStep) {
                                currentStep = EmotionalStep.allCases[currentIndex - 1]
                            }
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                    }
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .navigationTitle("When Emotions Take Over")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func completeFlow() {
        let note = EmotionalTakeoverNote(
            step2_bodySensation: bodySensation,
            step5_partNeed: partNeed.isEmpty ? nil : partNeed,
            step6_nextTimePlan: nextTimePlan,
            completedAllSteps: true
        )
        onComplete(note)
    }
}

// MARK: - Step Views

struct NameItStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
            
            Text("Old memory, new trigger")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Something from the past got stirred up. My body is reacting to an old danger, not right now.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Next", action: onNext)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .padding()
    }
}

struct NoticeBodyStep: View {
    @Binding var bodySensation: String
    let onNext: () -> Void
    
    @State private var selectedPrompt = ""
    @State private var customText = ""
    @State private var showingTextCapture = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let bodyPrompts = [
        "stomach tightness",
        "heat in face", 
        "hollow chest",
        "tension in shoulders",
        "racing heart",
        "shallow breathing"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Where do you feel this in your body?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            // Prompt chips
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(bodyPrompts, id: \.self) { prompt in
                    Button(prompt) {
                        selectedPrompt = prompt
                        bodySensation = prompt
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedPrompt == prompt ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(buttonTextColor(for: prompt))
                    .font(.subheadline)
                    .accessibilityLabel(prompt)
                    .accessibilityHint("Select \(prompt) as where you feel this emotion")
                    .accessibilityAddTraits(selectedPrompt == prompt ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal)
            
            // Custom input
            VStack(alignment: .leading, spacing: 8) {
                Text("Or describe it in your own words:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button("Add custom description") {
                    showingTextCapture = true
                }
                .foregroundColor(colorScheme == .dark ? .white : .blue)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            if !bodySensation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you're feeling:")
                        .font(.headline)
                    
                    Text(bodySensation)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                .padding(.horizontal)
            }
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .disabled(bodySensation.isEmpty)
                .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showingTextCapture) {
            CustomBodySensationView(bodySensation: $bodySensation)
        }
    }
    
    private func buttonTextColor(for prompt: String) -> Color {
        if selectedPrompt == prompt {
            return .white
        } else {
            return colorScheme == .dark ? .white : .primary
        }
    }
}

struct CompleteStressCycleStep: View {
    let onNext: () -> Void
    
    @State private var showingBreathingGuide = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Let your body complete the stress cycle")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Try the Voo breath technique: Find a comfortable position, take a deep breath in, then exhale with a deep 'voo' sound from your belly. Feel the vibration and repeat for a few minutes. If you need a quiet option, follow the same pattern silently. Use either guide to help with timing your breaths")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            Text("After breathing, try shaking your hands, tensing-and-releasing your fists or shoulders, or doing some gentle movement to help release any remaining tension.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            // Breathing button (styled like the working version)
            Button(action: { showingBreathingGuide = true }) {
                HStack {
                    Image(systemName: "lungs.fill")
                        .foregroundStyle(colorScheme == .dark ? .white : .blue)
                    Text("Click here to do 3 calming breaths")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
            .padding(.horizontal)
            
            Button("Done") {
                onNext()
            }
            .buttonStyle(.bordered)
            .foregroundColor(colorScheme == .dark ? .white : .blue)
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showingBreathingGuide) {
            MiniCoachBreathingView()
        }
    }
    
}

struct PendulateStep: View {
    @Binding var comfortableThings: [String]
    let onNext: () -> Void
    
    @State private var timerCompleted = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Pendulate Between Discomfort and Safety")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Feel it for 5-10 seconds, then look around and name 3 pleasant things.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ProgressTimerButton(
                title: "Feel it for 10 seconds",
                duration: 10.0
            ) {
                timerCompleted = true
            }
            .padding(.horizontal)
            
            if timerCompleted {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Now look around and name 3 pleasant things you see:")
                        .font(.headline)
                        .padding(.top)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    ForEach(0..<3, id: \.self) { index in
                        ZStack(alignment: .leading) {
                            if comfortableThings[index].isEmpty {
                                Text("Thing \(index + 1)")
                                    .foregroundColor(colorScheme == .dark ? .white : .secondary)
                                    .padding(.horizontal, 8)
                            }
                            TextField("", text: $comfortableThings[index])
                                .textFieldStyle(.roundedBorder)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .accessibilityLabel("Comfortable thing \(index + 1)")
                                .accessibilityHint("Name something comfortable or pleasant you see")
                        }
                    }
                }
                .padding(.horizontal)
                
                Button("Continue", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .disabled(comfortableThings.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                    .padding(.top)
            }
        }
        .padding()
    }
}

struct SoothePartStep: View {
    @Binding var partNeed: String
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(.pink)
            
            Text("Soothe the Part that Reached for Food")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Talk to the part of you that needed something. Thank it for trying to help, then ask what it really needs.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What did this part need? (optional)")
                    .font(.headline)
                
                Text("Example: 'I needed comfort' or 'I needed to feel safe' or 'I needed to escape this feeling'")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                TextField("What did this part need?", text: $partNeed, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            .padding(.horizontal)
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .padding()
    }
}

struct RehearsePlanStep: View {
    @Binding var nextTimePlan: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            Text("Rehearse a Gentle Next-Time Plan")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("If this same conflict came up again, what could my adult self try first?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your plan:")
                    .font(.headline)
                
                TextField("Try taking 3 deep breaths first, then...", text: $nextTimePlan, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)
            }
            .padding(.horizontal)
            
            Button("Complete", action: onComplete)
                .buttonStyle(.borderedProminent)
                .disabled(nextTimePlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.top)
        }
        .padding()
    }
}

struct CustomBodySensationView: View {
    @Binding var bodySensation: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var textInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Describe what you're feeling in your body")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                
                TextEditor(text: $textInput)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .frame(minHeight: 120)
                
                Spacer()
                
                Button("Save") {
                    bodySensation = textInput
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(colorScheme == .dark ? .gray : .blue)
                .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("Custom Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
    }
}

#Preview {
    EmotionalTakeoverFlow { note in
        print("Completed: \(note)")
    }
}


