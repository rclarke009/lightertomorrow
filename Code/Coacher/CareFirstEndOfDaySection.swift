//
//  CareFirstEndOfDaySection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct CareFirstEndOfDaySection: View {
    @Binding var entry: DailyEntry
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    
    // New care-first flow state
    @State private var currentStep = 0
    @State private var showingWarmValidation = false
    @State private var validationMessage = ""
    @State private var isInitialLoad = true
    @State private var dayCompleted = false
    @State private var prepCompleted = false
    
    // Checklist state
    @State private var waterBottleReady = false
    @State private var prepBreakfast = false
    @State private var stickyNote = false
    @State private var workoutClothes = false
    @State private var customItem = ""
    @State private var customItemChecked = false
    
    // Morning focus reflection state
    @State private var showingAlternativeHelp = false
    
    let onCelebrationTrigger: (String, String) -> Void
    let scrollProxy: ScrollViewProxy?
    
    // Check if user completed morning focus today
    private var hasMorningFocusToday: Bool {
        !entry.todaysFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !entry.stressResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Progress indicator
            ProgressView(
                value: hasMorningFocusToday ? 
                    (currentStep == 5 ? 6.0 : Double(currentStep)) : 
                    (currentStep == 4 ? 5.0 : Double(currentStep)), 
                total: hasMorningFocusToday ? 6.0 : 5.0
            )
                .progressViewStyle(LinearProgressViewStyle(tint: Color.helpButtonBlue))
                .scaleEffect(x: 1, y: 0.8)
            
            // Step content
            if hasMorningFocusToday {
                // Full flow for users who completed morning focus
                switch currentStep {
                case 0:
                    warmEntryStep
                case 1:
                    calmReflectionStep
                case 2:
                    comfortEatingReflectionStep
                case 3:
                    prepSmallWinsStep
                case 4:
                    selfCompassionStep
                case 5:
                    completionMessageStep
                default:
                    EmptyView()
                }
            } else {
                // Shortened flow for new users who haven't done morning focus
                switch currentStep {
                case 0:
                    calmReflectionStep
                case 1:
                    comfortEatingReflectionStep
                case 2:
                    prepSmallWinsStep
                case 3:
                    selfCompassionStep
                case 4:
                    completionMessageStep
                default:
                    EmptyView()
                }
            }
            
            // Navigation buttons
            if hasMorningFocusToday ? currentStep > 0 : true {
                HStack {
                    if (hasMorningFocusToday && currentStep > 1) || (!hasMorningFocusToday && currentStep > 0) {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !nextButtonTitle.isEmpty {
                        Button(nextButtonTitle) {
                            handleNextStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.helpButtonBlue)
                        .disabled(!canProceed)
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            loadSavedData()
            checkDayCompletion()
            
            // Mark initial load as complete after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitialLoad = false
            }
        }
        .onChange(of: entry.didCareAction) { _, _ in
            checkForCelebration()
        }
        .onChange(of: entry.smallWinsForTomorrow) { _, _ in
            checkForCelebration()
        }
        .overlay(
            WarmValidationOverlay(isPresented: $showingWarmValidation)
        )
    }
    
    // MARK: - Step Views
    
    private var warmEntryStep: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Give yourself a pat on the back — you're showing up to make a better tomorrow.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Check In button
            Button("Check In") {
                showWarmValidation()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            
            Spacer()
        }
        .padding()
    }
    
    private var celebrateShowingUpStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("2")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Care in Action")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                

            }
            
            VStack(alignment: .leading, spacing: 20) {
                // Step 1: Did you follow your care action?
                VStack(alignment: .leading, spacing: 8) {
                    Text("Did your care action help you today?")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    // Display today's care action plan
                    if !entry.todaysFocus.isEmpty || !entry.stressResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's plan was:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !entry.todaysFocus.isEmpty {
                                Text("\"\(entry.todaysFocus)\"")
                                    .font(.subheadline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .italic()
                            }
                            
                            if !entry.stressResponse.isEmpty {
                                Text("\"\(entry.stressResponse)\"")
                                    .font(.subheadline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Text("(Even noticing your stress counts as a win)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                // Step 2: Reflect
                // VStack(alignment: .leading, spacing: 8) {
                //     Text("Reflect")
                //         .font(.headline)
                //         .fontWeight(.bold)
                //         .foregroundColor(.primary)
                    
                //     Text("How did it feel to care for yourself today?")
                //         .font(.subheadline)
                //         .foregroundColor(.secondary)
                // }
                
                // // Step 3: What to adjust for tomorrow
                // VStack(alignment: .leading, spacing: 8) {
                //     Text("What to adjust for tomorrow")
                //         .font(.headline)
                //         .fontWeight(.bold)
                //         .foregroundColor(.primary)
                    
                //     Text("What would help you feel more supported?")
                //         .font(.subheadline)
                //         .foregroundColor(.secondary)
                // }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Yes") {
                        entry.didCareAction = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.helpButtonBlue)
                    
                    Button("No") {
                        entry.didCareAction = false
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var calmReflectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text(hasMorningFocusToday ? "1" : "1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("What Helped You Feel Calm")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if hasMorningFocusToday {
                    Text("This builds awareness without shame—awareness is what creates change.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Welcome! Let's take a moment to reflect and prep for tomorrow's success.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What helped you feel calm or cared for today?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: $entry.whatHelpedCalm, selectAllOnTap: true)
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
                        .accessibilityLabel("What helped you feel calm")
                        .accessibilityHint("What helped you feel calm or cared for today?")
                        .id("whatHelpedCalm")
                        .onTapGesture {
                            scrollToField("whatHelpedCalm")
                        }
                    
                    if entry.whatHelpedCalm.isEmpty {
                        Text("Examples: took a walk, called a friend, did some breathing exercises")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
    
    private var comfortEatingReflectionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text(hasMorningFocusToday ? "2" : "1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Comfort Eating Reflection")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Understanding triggers helps us prepare for next time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Was there a moment you felt pulled toward comfort eating?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("What was happening inside or around you?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: Binding(
                        get: { entry.comfortEatingMoment ?? "" },
                        set: { entry.comfortEatingMoment = $0.isEmpty ? nil : $0 }
                    ), selectAllOnTap: true)
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
                        .accessibilityLabel("Comfort eating moment")
                        .accessibilityHint("What was happening when you felt pulled toward comfort eating?")
                        .id("comfortEatingMoment")
                        .onTapGesture {
                            scrollToField("comfortEatingMoment")
                        }
                    
                    if entry.comfortEatingMoment?.isEmpty != false {
                        Text("Examples: felt stressed about work, felt lonely, felt tired")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                
                // Morning focus callout (only for users with morning focus)
                if hasMorningFocusToday && !entry.todaysFocus.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .foregroundColor(.helpButtonBlue)
                                .font(.caption)
                            
                            Text("Today's plan: \"\(entry.todaysFocus)\"")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .lineLimit(2)
                            
                            Spacer()
                        }
                        
                        if !entry.stressResponse.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.helpButtonBlue)
                                    .font(.caption)
                                
                                Text("If stressed: \"\(entry.stressResponse)\"")
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .lineLimit(2)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.helpButtonBlue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.helpButtonBlue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Care action question (only for users with morning focus)
                if hasMorningFocusToday {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Did your care action help you today?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 16) {
                            Button("Yes") {
                                entry.didCareAction = true
                                showingAlternativeHelp = false
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            
                            Button("No") {
                                entry.didCareAction = false
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingAlternativeHelp = true
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.secondary)
                        }
                        
                        if showingAlternativeHelp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("I am allowed to forgive myself for the moments I didn't.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                                
                                Text("What's one small way I can show up for myself tomorrow?")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ZStack(alignment: .topLeading) {
                                    SelectableTextEditor(text: Binding(
                                        get: { entry.whatElseCouldHelp ?? "" },
                                        set: { entry.whatElseCouldHelp = $0.isEmpty ? nil : $0 }
                                    ), selectAllOnTap: true)
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
                                        .accessibilityLabel("What's one small way I can show up for myself tomorrow")
                                        .accessibilityHint("What's one small way I can show up for myself tomorrow?")
                                        .id("whatElseCouldHelp")
                                        .onTapGesture {
                                            scrollToField("whatElseCouldHelp")
                                        }
                                    
                                    if entry.whatElseCouldHelp?.isEmpty != false {
                                        Text("Examples: prep a healthy breakfast, set a reminder to breathe, go to bed 10 minutes earlier")
                                            .foregroundColor(.secondary)
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var prepSmallWinsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Morning focus callout (only for users with morning focus)
            if hasMorningFocusToday && !entry.todaysFocus.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "target")
                            .foregroundColor(.helpButtonBlue)
                            .font(.caption)
                        
                        Text("Today's plan: \"\(entry.todaysFocus)\"")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    
                    if !entry.stressResponse.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.helpButtonBlue)
                                .font(.caption)
                            
                            Text("If stressed: \"\(entry.whatElseCouldHelp?.isEmpty == false ? entry.whatElseCouldHelp! : entry.stressResponse)\"")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.helpButtonBlue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.helpButtonBlue.opacity(0.3), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text(hasMorningFocusToday ? "3" : "2")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("Prep a Win for Tomorrow")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(dynamicPrepQuestion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Checklist items
                VStack(spacing: 8) {
                    ChecklistItem(
                        isChecked: $waterBottleReady,
                        text: "Water bottle ready",
                        onToggle: { }
                    )
                    
                    ChecklistItem(
                        isChecked: $prepBreakfast,
                        text: "Prep easy breakfast/snack",
                        onToggle: { }
                    )
                    
                    ChecklistItem(
                        isChecked: $stickyNote,
                        text: "Sticky note where I'll see it",
                        onToggle: { }
                    )
                    
                    ChecklistItem(
                        isChecked: $workoutClothes,
                        text: "Lay out workout clothes",
                        onToggle: { }
                    )
                    
                    // Custom item
                    HStack(spacing: 12) {
                        Button(action: {
                            // Only allow checking if there's text, always allow unchecking
                            if customItemChecked {
                                // Unchecking - always allowed
                                customItemChecked = false
                            } else {
                                // Checking - only if there's text
                                if !customItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    customItemChecked = true
                                }
                            }
                        }) {
                            Image(systemName: customItemChecked ? "checkmark.square.fill" : "square")
                                .foregroundColor(customItemChecked ? .helpButtonBlue : .secondary)
                                .font(.title2)
                        }
                        
                        TextField("Custom:", text: $customItem)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(customItemChecked)
                    }
                }
                
                // Encouraging microcopy
                Text("Future You will feel the difference tomorrow.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
    }
    
    private var selfCompassionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text(hasMorningFocusToday ? "4" : "3")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("End With Self-Compassion")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("End the day with kindness.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.helpButtonBlue)
                    
                    Text("This is hard, and I'm not alone. I can be kind to myself as I grow.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.helpButtonBlue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.helpButtonBlue.opacity(0.3), lineWidth: 1)
                )
                
                Button("Mark Day Complete") {
                    completeEveningFlow()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.helpButtonBlue)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var completionMessageStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("🎉 Great Job!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("You completed your end-of-day check-in.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Take a moment to appreciate yourself for showing up today.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .italic()

                
                
                // Text("This screen will stay here until tomorrow morning.")
                //     .font(.caption)
                //     .foregroundColor(.secondary)
                //     .multilineTextAlignment(.center)
                //     .padding(.top, 8)
                
                // Encouraging phrase that appears after completion
                VStack(spacing: 4) {

                    Text("\(celebrationManager.getCelebrationMessage(for: true))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("🎈 🎈 🎈")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var nextButtonTitle: String {
        if hasMorningFocusToday {
            switch currentStep {
            case 0: return "" // Handled by Check In button
            case 1: return "Next" // Calm reflection
            case 2: return entry.didCareAction == true ? "" : "Next" // Auto-advance if Yes, show Next if No
            case 3: return "Next" // Show Next button when items are checked
            case 4: return "" // Handled by Mark Day Complete button
            case 5: return "Reset" // Completion message step
            default: return "Next"
            }
        } else {
            switch currentStep {
            case 0: return "Next" // Calm reflection
            case 1: return "Next" // Comfort eating reflection
            case 2: return "Next" // Show Next button when items are checked
            case 3: return "" // Handled by Mark Day Complete button
            case 4: return "Reset" // Completion message step
            default: return "Next"
            }
        }
    }
    
    private var canProceed: Bool {
        if hasMorningFocusToday {
            switch currentStep {
            case 0: return false // Handled by Check In button
            case 1: return true // Can always proceed from calm reflection
            case 2: return entry.didCareAction == true ? false : canProceedFromComfortEatingReflection // Auto-advance if Yes, validate if No
            case 3: return hasAnyChecklistItemChecked // Must check at least one item
            case 4: return true // Handled by Mark Day Complete button
            case 5: return true // Completion message step
            default: return false
            }
        } else {
            switch currentStep {
            case 0: return true // Can always proceed from calm reflection
            case 1: return true // Can always proceed from comfort eating reflection
            case 2: return hasAnyChecklistItemChecked // Must check at least one item
            case 3: return true // Handled by Mark Day Complete button
            case 4: return true // Completion message step
            default: return false
            }
        }
    }
    
    private var canProceedFromComfortEatingReflection: Bool {
        // Must answer the care action question
        guard let didCareAction = entry.didCareAction else { return false }
        
        // If they said no, they must have filled in the alternative
        if !didCareAction {
            return !(entry.whatElseCouldHelp?.isEmpty ?? true)
        }
        
        return true
    }
    
    private var hasAnyChecklistItemChecked: Bool {
        return waterBottleReady || prepBreakfast || stickyNote || workoutClothes || customItemChecked
    }
    
    private var dynamicPrepQuestion: String {
        if hasMorningFocusToday {
            if entry.didCareAction == true {
                return "Do you need to prepare anything to get that win again tomorrow?"
            } else {
                return "Do you need to prepare anything to get that win tomorrow?"
            }
        } else {
            return "What will make it easy to make healthy choices tomorrow?"
        }
    }
    
    // MARK: - Actions
    
    private func handleNextStep() {
        if hasMorningFocusToday {
            if currentStep < 4 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep += 1
                }
            } else if currentStep == 5 {
                // Reset when user clicks "Reset" - clear completion and go back to start
                UserDefaults.standard.removeObject(forKey: "dayCompletedDate")
                dayCompleted = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 0
                }
            }
        } else {
            if currentStep < 3 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep += 1
                }
            } else if currentStep == 4 {
                // Reset when user clicks "Reset" - clear completion and go back to start
                UserDefaults.standard.removeObject(forKey: "dayCompletedDate")
                dayCompleted = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 0
                }
            }
        }
    }
    
    private func completeEveningFlow() {
        // Save data
        saveData()
        
        // Mark that user has ever completed end-of-day check-in
        UserDefaults.standard.set(true, forKey: "hasEverCompletedEndOfDay")
        
        // Mark today as completed
        UserDefaults.standard.set(Date(), forKey: "dayCompletedDate")
        dayCompleted = true
        
        // Trigger medium celebration for completing the day
        celebrationManager.triggerCelebration(for: .dayComplete)
        
        // Record activity for streak tracking
        celebrationManager.recordActivity()
        
        // Go to completion message step
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = hasMorningFocusToday ? 5 : 4
        }
    }
    
    private func showWarmValidation() {
        validationMessage = celebrationManager.getWarmValidationMessage()
        showingWarmValidation = true
        
        // Auto-dismiss after 3 seconds and advance to next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showingWarmValidation = false
            // Advance to next step if we're on the warm entry step (only for full flow)
            if currentStep == 0 && hasMorningFocusToday {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep += 1
                }
            }
        }
    }
    
    private func checkDayCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = UserDefaults.standard.object(forKey: "dayCompletedDate") as? Date
        
        if let savedDate = savedDate, Calendar.current.isDate(savedDate, inSameDayAs: today) {
            // Day was completed today, show completion message
            dayCompleted = true
            currentStep = hasMorningFocusToday ? 5 : 4
        } else {
            // New day, start from beginning
            dayCompleted = false
            currentStep = 0
        }
    }
    
    private func checkForCelebration() {
        // Don't trigger celebrations during initial data load
        guard !isInitialLoad else { return }
        
        // Check if care action was completed
        if entry.didCareAction == true {
            celebrationManager.triggerCelebration(for: .careActionYes)
        }
    }
    
    private func loadSavedData() {
        // Only load the custom prep item for the checklist - reflection fields should be blank each day
        let savedCustomItem = UserDefaults.standard.string(forKey: "savedCustomPrepItem")
        if let savedCustomItem = savedCustomItem, !savedCustomItem.isEmpty {
            customItem = savedCustomItem
        }
    }
    
    private func saveData() {
        // Only save the custom prep item to UserDefaults - reflection fields are unique to each day
        if !customItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(customItem, forKey: "savedCustomPrepItem")
        }
        
        // Save to SwiftData so it appears in history
        do {
            try context.save()
            print("🔍 DEBUG: Saved DailyEntry to SwiftData for history")
        } catch {
            print("❌ DEBUG: Failed to save DailyEntry to SwiftData: \(error)")
        }
    }
    
    private func scrollToField(_ fieldId: String) {
        guard let scrollProxy = scrollProxy else { return }
        
        // Add a small delay to ensure the keyboard animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                scrollProxy.scrollTo(fieldId, anchor: .center)
            }
        }
    }
    
}

// MARK: - Warm Validation Overlay

struct WarmValidationOverlay: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var showContent = false
    
    var body: some View {
        if isPresented {
            GeometryReader { geometry in
                ZStack {
                    // Transparent background - no overlay
                    Color.clear
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissCelebration()
                        }
                    
                    // Centered celebration card
                    VStack(spacing: 20) {
                        // Gentle sparkle animation
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(.yellow)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showContent)
                        
                        Text("You showed up today. That matters.")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .scaleEffect(showContent ? 1.0 : 0.9)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContent = true
                }
                
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismissCelebration()
                }
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Checklist Item Component

struct ChecklistItem: View {
    @Binding var isChecked: Bool
    let text: String
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                isChecked.toggle()
                onToggle()
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .helpButtonBlue : .secondary)
                    .font(.title2)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .strikethrough(isChecked)
                .opacity(isChecked ? 0.6 : 1.0)
            
            Spacer()
        }
    }
}

// SelectableTextEditor is already defined in MorningFocusSection.swift

#Preview {
    ScrollView {
        CareFirstEndOfDaySection(
            entry: .constant(DailyEntry()),
            onCelebrationTrigger: { _, _ in },
            scrollProxy: nil
        )
        .padding()
    }
}
