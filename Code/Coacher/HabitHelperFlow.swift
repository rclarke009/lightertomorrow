//
//  HabitHelperFlow.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct HabitHelperFlow: View {
    let onComplete: (HabitHelperNote) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: HabitStep = .identifyPattern
    @State private var pattern = ""
    @State private var rewire = ""
    @State private var experimentCompleted = false
    @State private var showingCustomPatternInput = false
    
    enum HabitStep: Int, CaseIterable {
        case identifyPattern = 0, learn = 1, tryExperiment = 2, rewire = 3, encourage = 4
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: Double(currentStep.rawValue), total: Double(HabitStep.allCases.count - 1))
                    .padding(.horizontal)
                
                // Content based on current step
                switch currentStep {
                case .identifyPattern:
                    IdentifyPatternStep(pattern: $pattern, showingCustomInput: $showingCustomPatternInput) {
                        currentStep = .learn
                    }
                case .learn:
                    LearnStep {
                        currentStep = .tryExperiment
                    }
                case .tryExperiment:
                    TryExperimentStep(experimentCompleted: $experimentCompleted) {
                        currentStep = .rewire
                    }
                case .rewire:
                    RewireStep(rewire: $rewire) {
                        currentStep = .encourage
                    }
                case .encourage:
                    EncourageStep {
                        completeFlow()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep != .identifyPattern {
                        Button("Back") {
                            if let currentIndex = HabitStep.allCases.firstIndex(of: currentStep) {
                                currentStep = HabitStep.allCases[currentIndex - 1]
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
            .navigationTitle("Habit Helper")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCustomPatternInput) {
                CustomPatternInputView(pattern: $pattern)
            }
        }
    }
    
    private func completeFlow() {
        let note = HabitHelperNote(
            step1_pattern: pattern,
            step4_rewire: rewire,
            completedAllSteps: true
        )
        onComplete(note)
    }
}

// MARK: - Step Views

struct IdentifyPatternStep: View {
    @Binding var pattern: String
    @Binding var showingCustomInput: Bool
    let onNext: () -> Void
    
    @State private var selectedPattern = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private let commonPatterns = [
        "Just finished work",
        "Watching TV",
        "Feeling bored",
        "After a meal",
        "Before bed",
        "During a break"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Identify the Pattern")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("What were you doing just before the craving hit?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Quick-tap option chips
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(commonPatterns, id: \.self) { patternOption in
                        Button(patternOption) {
                            selectedPattern = patternOption
                            pattern = patternOption
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedPattern == patternOption ? Color.blue : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(selectedPattern == patternOption ? .white : (colorScheme == .dark ? .white : .primary))
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Custom input button
                Button("Custom") {
                    showingCustomInput = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(maxWidth: .infinity)
                
                // Display selected pattern
                if !pattern.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your pattern:")
                            .font(.headline)
                        
                        Text(pattern)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }
            }
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .disabled(pattern.isEmpty)
                .padding(.top)
        }
        .padding()
    }
}

struct LearnStep: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
            
            Text("Learn")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Text("Your brain links cues, routines, and rewards.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("This urge might be an automatic loop — not real hunger or emotion.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
                
                // Visual display
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Cue")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text("Trigger")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.purple)
                        .font(.title3)
                    
                    VStack(spacing: 4) {
                        Text("Routine")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text("Behavior")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.purple)
                        .font(.title3)
                    
                    VStack(spacing: 4) {
                        Text("Reward")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text("Feeling")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .padding()
    }
}

struct TryExperimentStep: View {
    @Binding var experimentCompleted: Bool
    let onNext: () -> Void
    
    @State private var selectedAction: ExperimentAction?
    @State private var showingTimer = false
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    
    enum ExperimentAction: String, CaseIterable {
        case pause = "⏸ Pause 30 seconds"
        case stretch = "🚶 Stretch / step outside"
        case water = "💧 Drink water"
        case music = "🎵 Play one song"
        
        var icon: String {
            switch self {
            case .pause: return "pause.circle.fill"
            case .stretch: return "figure.walk"
            case .water: return "drop.fill"
            case .music: return "music.note"
            }
        }
        
        var color: Color {
            switch self {
            case .pause: return .orange
            case .stretch: return .green
            case .water: return .blue
            case .music: return .purple
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flask")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Try an Experiment")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("See if the craving fades. Awareness weakens the loop. Choose an activity like those below.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            if showingTimer {
                timerView
            } else if experimentCompleted {
                completionView
            } else {
                experimentOptionsView
            }
        }
        .padding()
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var experimentOptionsView: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(ExperimentAction.allCases, id: \.self) { action in
                    Button(action.rawValue) {
                        selectedAction = action
                        startExperiment(action)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(action.color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(action.color, lineWidth: 2)
                            )
                    )
                    .foregroundColor(action.color)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var timerView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedAction?.icon ?? "timer")
                .font(.system(size: 60))
                .foregroundStyle(selectedAction?.color ?? .blue)
            
            Text("\(timeRemaining)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(selectedAction?.color ?? .blue)
            
            Text(selectedAction?.rawValue ?? "Experiment in progress...")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if selectedAction == .pause {
                Text("Notice how the craving feels now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Experiment Complete!")
                .font(.title2)
                .bold()
            
            Text("How did that feel? Did the craving change?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
    }
    
    private func startExperiment(_ action: ExperimentAction) {
        if action == .pause {
            showingTimer = true
            timeRemaining = 30
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                timeRemaining -= 1
                if timeRemaining <= 0 {
                    completeExperiment()
                }
            }
        } else {
            // For other actions, just show completion immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completeExperiment()
            }
        }
    }
    
    private func completeExperiment() {
        timer?.invalidate()
        timer = nil
        showingTimer = false
        experimentCompleted = true
    }
}

struct RewireStep: View {
    @Binding var rewire: String
    let onNext: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
            
            Text("Rewire")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Next time this cue shows up, what would feel rewarding instead?")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What would feel rewarding instead of food?")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $rewire)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .background(Color(.systemBackground))
                        .focused($isTextFieldFocused)
                        .onTapGesture {
                            isTextFieldFocused = true
                        }
                    
                    if rewire.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTextFieldFocused {
                        Text("Try taking a walk, calling a friend, or doing 5 minutes of deep breathing...")
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal)
            
            Button("Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .disabled(rewire.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.top)
        }
        .padding()
    }
}

struct EncourageStep: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("🌱")
                .font(.system(size: 80))
            
            Text("One healthier pattern planted.")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("You're building awareness and creating new habits. Every small step counts.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Complete", action: onComplete)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
        .padding()
    }
}

struct CustomPatternInputView: View {
    @Binding var pattern: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var textInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "repeat.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .accessibilityLabel("Pattern input")
                        .accessibilityHidden(false)
                    
                    Text("Custom Pattern")
                        .font(.title2)
                        .bold()
                    
                    Text("What were you doing just before the craving hit?")
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
                    Text("Your pattern:")
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
                        .accessibilityLabel("Your pattern")
                        .accessibilityHint("Describe what you were doing before the craving hit")
                    
                    Text("Examples: Just finished work, watching TV, feeling bored, after a meal...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        pattern = textInput
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
            .navigationTitle("Custom Pattern")
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
                textInput = pattern
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    HabitHelperFlow { note in
        print("Completed: \(note)")
    }
}
