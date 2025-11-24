//
//  EndOfDaySection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct MorningFocusSection: View {
    @Binding var entry: DailyEntry
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var reminderManager = ReminderManager.shared
    @State private var showWhyNudge = false
    @State private var showingWhyInfo = false
    let onCelebrationTrigger: (String, String) -> Void = { _, _ in }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step 1 – My Why
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("My Why")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { showingWhyInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.brightBlue)
                    }
                }

                ZStack(alignment: .topLeading) {
                    SelectableTextEditor(text: $entry.myWhy, selectAllOnTap: true)
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
                            .accessibilityLabel("My Why")
                            .accessibilityHint("Enter your personal motivation, your why for making healthy choices today")
                    
                    // Placeholder text overlay
                    if entry.myWhy.isEmpty {
                        Text("Type your personal motivation, your why for making healthy choices today.")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                
               


                // 3-day nudge for refreshing "Why"
                if showWhyNudge {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Still true? Refreshing your Why brings renewed energy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
                .frame(height: 16)
            
            // Step 2 – Identify a Challenge
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
                    Text("Focus on a Challenge")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Menu {
                    Button("Skipping meals") { 
                        entry.challenge = .skippingMeals
                        UserDefaults.standard.set("skippingMeals", forKey: "lastSelectedChallenge")
                    }
                    Button("Late-night snacking") { 
                        entry.challenge = .lateNightSnacking
                        UserDefaults.standard.set("lateNightSnacking", forKey: "lastSelectedChallenge")
                    }
                    Button("Sugary drinks") { 
                        entry.challenge = .sugaryDrinks
                        UserDefaults.standard.set("sugaryDrinks", forKey: "lastSelectedChallenge")
                    }
                    Button("Eating on the go / fast food") { 
                        entry.challenge = .onTheGo
                        UserDefaults.standard.set("onTheGo", forKey: "lastSelectedChallenge")
                    }
                    Button("Emotional eating") { 
                        entry.challenge = .emotionalEating
                        UserDefaults.standard.set("emotionalEating", forKey: "lastSelectedChallenge")
                    }
                    Button("Other") { 
                        entry.challenge = .other
                        UserDefaults.standard.set("other", forKey: "lastSelectedChallenge")
                    }
                } label: {
                    HStack {
                        Text(entry.challenge == .none ? "Select…" : entry.challenge.displayName)
                            .foregroundColor(entry.challenge == .none ? .teal : Color(.label))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.teal)
                            .font(.caption)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                    )
                }
                
                if entry.challenge == .other {
                    TextEditor(text: $entry.challengeOther)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .font(.subheadline)
                        .background(colorScheme == .dark ? Color.blue : Color.clear)
                        .padding(0)
                        .frame(minHeight: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                        )
                        .accessibilityLabel("Other challenge")
                        .accessibilityHint("Describe the specific challenge you're facing")
                }
            }
            
            Spacer()
                .frame(height: 16)
            
            // Step 3 – My Better Choice (Swap)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.helpButtonBlue)
                            .frame(width: 24, height: 24)
                        Text("3")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text("My Better Choice")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if entry.challenge != .none {
                    Text("In step 2, you mentioned \(entry.challenge.displayName.lowercased()), let's choose a healthy swap.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 4)
                }
                
HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today I will...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $entry.commitTo)
                            .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                            .font(.subheadline)
                            .background(colorScheme == .dark ? Color.blue : Color.clear)
                                
                                //.background(Color.clear)   // clears system bg

                            .padding(0)
                            .frame(minHeight: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                            )
                            .accessibilityLabel("Today I will")
                            .accessibilityHint("Enter what you commit to doing today")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("instead of...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $entry.commitFrom)
                            .foregroundColor(colorScheme == .dark ? .white : Color(.label))
                            .font(.subheadline)
                            .background(colorScheme == .dark ? Color.blue : Color.clear)
                            .padding(0)
                            .frame(minHeight: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
                            )
                            .accessibilityLabel("Instead of")
                            .accessibilityHint("Enter what you're avoiding or replacing")
                    }
                }
            }
            
            
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Load saved challenge if current entry doesn't have one selected
            if entry.challenge == .none {
                let savedChallengeRaw = UserDefaults.standard.string(forKey: "lastSelectedChallenge")
                if let savedChallengeRaw = savedChallengeRaw,
                   let savedChallenge = Challenge(rawValue: savedChallengeRaw) {
                    entry.challenge = savedChallenge
                }
            }
            
            // Load saved "why" if current entry doesn't have one
            if entry.myWhy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let savedWhy = UserDefaults.standard.string(forKey: "savedMyWhy")
                if let savedWhy = savedWhy, !savedWhy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    entry.myWhy = savedWhy
                }
            }
            
            // Check for 3-day "Why" nudge
            checkWhyNudge()
        }
        .onChange(of: entry.myWhy) { _, newValue in
            // Save the "why" when it changes
            saveWhy(newValue)
        }
        .onChange(of: entry.commitTo) { _, newValue in
            // Check if morning focus is completed (both commit fields filled)
            if !newValue.isEmpty && !entry.commitFrom.isEmpty {
                reminderManager.cancelMorningReminder()
            }
        }
        .onChange(of: entry.commitFrom) { _, newValue in
            // Check if morning focus is completed (both commit fields filled)
            if !newValue.isEmpty && !entry.commitTo.isEmpty {
                reminderManager.cancelMorningReminder()
            }
        }
        .sheet(isPresented: $showingWhyInfo) {
            WhyInfoView()
        }
    }










    
    // MARK: - Why Persistence and Nudge Logic
    
    private func saveWhy(_ whyText: String) {
        // Only save if the text is not empty
        guard !whyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        UserDefaults.standard.set(whyText, forKey: "savedMyWhy")
        UserDefaults.standard.set(Date(), forKey: "whyLastUpdated")
    }
    
    private func checkWhyNudge() {
        // Only show nudge if user has a "why" entered
        guard !entry.myWhy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showWhyNudge = false
            return
        }
        
        // Check if it's been 3+ days since last update
        if let lastUpdated = UserDefaults.standard.object(forKey: "whyLastUpdated") as? Date {
            let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
            
            // Show nudge if it's been 3 or more days and the current "why" matches the saved one
            let savedWhy = UserDefaults.standard.string(forKey: "savedMyWhy") ?? ""
            if daysSinceUpdate >= 3 && entry.myWhy == savedWhy {
                showWhyNudge = true
            } else {
                showWhyNudge = false
            }
        } else {
            // No previous update recorded, so no nudge needed yet
            showWhyNudge = false
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WhyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's a good Why?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                // Intro
                VStack(alignment: .leading, spacing: 12) {
                    Text("\"Your Why is the deeper reason behind making healthier choices. It's about the life you want, not just the number on the scale.\"")
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBlue).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(.systemBlue).opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Sample Whys
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Whys from others:")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"I want steady energy so I can focus at school and not crash in the afternoon.\"")
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                        
                        Text("\"I want to feel comfortable in my clothes and confident at family gatherings.\"")
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                        
                        Text("\"I want to set a good example for my kids so they see food as fuel, not stress.\"")
                            .font(.body)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    }
                }
                
                // Encouragement
                VStack(alignment: .leading, spacing: 8) {
                    Text("\"Write one sentence that feels helpful to you. Short and personal is best.\"")
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBlue).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(.systemBlue).opacity(0.3), lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("My Why")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brightBlue)
                }
            }
        }
    }
}

#Preview {
    MorningFocusSection(entry: .constant(DailyEntry()))
}



// //
// //  MorningFocusSection.swift
// //  Coacher
// //
// //  Created by Rebecca Clarke on 8/30/25.
// //

// import SwiftUI
// import SwiftData

// struct MorningFocusSection: View {
//     @Binding var entry: DailyEntry
//     @StateObject private var reminderManager = ReminderManager.shared
//     @Environment(\.colorScheme) private var colorScheme
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             // Step 1 – My Why
//             HStack {
//                 Text("①")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.blue)
//                 Text("My Why (2 minutes)")
//                     .font(.headline)
//                     .fontWeight(.semibold)
//                     .foregroundColor(.blue)
//                 Spacer()
//             }
//             .padding(.bottom, 8)
            
//             // TextEditor(text: $entry.myWhy)
//             //     .frame(minHeight: 60) // Two lines, expandable
//             //     .foregroundColor(colorScheme == .dark ? .white : .primary)
//             //     .background(colorScheme == .dark ? Color.darkTextInputBackground : Color.clear)
//             //     .padding(2)
//             //     .overlay(
//             //         RoundedRectangle(cornerRadius: 8)
//             //             .stroke(Color(.systemGray2), lineWidth: 0.25)
//             //     )
//            TextEditor(text: $entry.myWhy)
//                 .frame(minHeight: 60)
//                 .foregroundColor(colorScheme == .dark ? .white : .primary)
//                 .background(colorScheme == .dark ? Color.blue : Color.clear)
//                 .padding(2)
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 8)
//                         .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
//                 )

//                 .accessibilityLabel("My Why")
//                 .accessibilityHint("Enter your personal motivation for making healthy choices today")
                
//             // StepCard(stepNumber: "①", accentColor: .blue) {
//                 //VStack(alignment: .leading, spacing: 8) {
//                     // Text("My Why (2 minutes)")
//                         // .font(.headline)
//                         // .fontWeight(.semibold)
//                         // .foregroundColor(.blue)
                    
//                     // TextEditor(text: $entry.myWhy)
//                     //     .frame(minHeight: 60) // Two lines, expandable
//                     //     .foregroundColor(.primary)
//                 //}
//             //             }
            
//             // Add more space before step 2
//             Spacer()
//                 .frame(height: 24)
            
//             // Step 2 – Identify a Challenge
//             HStack {
//                 Text("②")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.teal)
//                 Text("Identify a Challenge (3 minutes)")
//                     .font(.headline)
//                     .fontWeight(.semibold)
//                     .foregroundColor(.teal)
//                 Spacer()
//             }
//             .padding(.bottom, 4)
            
//             Menu {
//                 Button("Skipping meals") { entry.challenge = .skippingMeals }
//                 Button("Late-night snacking") { entry.challenge = .lateNightSnacking }
//                 Button("Sugary drinks") { entry.challenge = .sugaryDrinks }
//                 Button("Eating on the go / fast food") { entry.challenge = .onTheGo }
//                 Button("Emotional eating") { entry.challenge = .emotionalEating }
//                 Button("Other") { entry.challenge = .other }
//             } label: {
//                 HStack {
//                     Text(entry.challenge == .none ? "Select…" : entry.challenge.displayName)
//                         .foregroundColor(entry.challenge == .none ? .teal : Color(.label))
//                     Spacer()
//                     Image(systemName: "chevron.down")
//                         .foregroundColor(.teal)
//                         .font(.caption)
//                 }
//                 .padding(12)
//             }
            
//             if entry.challenge == .other {
//                 TextEditor(text: $entry.challengeOther)
//                     .foregroundColor(colorScheme == .dark ? .white : .primary)
//                     .font(.subheadline)
//                     .background(colorScheme == .dark ? Color.blue : Color.clear)
//                     .padding(2)
//                     .frame(minHeight: 60) // Two rows to start, expandable
//                     .overlay(
//                         RoundedRectangle(cornerRadius: 8)
//                             .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
//                     )
//                     .accessibilityLabel("Other challenge")
//                     .accessibilityHint("Describe the specific challenge you're facing")
//             }
            
//             // Add space before step 3
//             Spacer()
//                 .frame(height: 24)
            
//             // Step 3 – Choose My Swap
//             HStack {
//                 Text("③")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.purple)
//                 Text("Choose My Swap (3 minutes)")
//                     .font(.headline)
//                     .fontWeight(.semibold)
//                     .foregroundColor(.purple)
//                 Spacer()
//             }
//             .padding(.bottom, 8)
            
//             TextEditor(text: $entry.chosenSwap)
//                 .foregroundColor(colorScheme == .dark ? .white : Color(.label))
//                 .font(.subheadline)
//                 .background(colorScheme == .dark ? Color.blue : Color.clear)
//                 .padding(2)
//                 .frame(minHeight: 60) // Two rows to start, expandable
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 8)
//                         .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
//                 )
//                 .accessibilityLabel("My Swap")
//                 .accessibilityHint("Enter the healthy alternative you'll choose instead")
            
//             // Add space before step 4
//             Spacer()
//                 .frame(height: 24)
            
//             // Step 4 – Commit (Special treatment)
//             HStack {
//                 Text("④")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.blue)
//                 Text("Commit (2 minutes)")
//                     .font(.headline)
//                     .fontWeight(.semibold)
//                     .foregroundColor(.blue)
//                 Spacer()
//             }
//             .padding(.bottom, 8)
                
//                 VStack(spacing: 12) {
//                             HStack(spacing: 16) {
//                                 VStack(alignment: .leading, spacing: 4) {
//                                     Text("Today I will...")
//                                         .padding(.leading, 16)
                                    
//                                     TextEditor(text: $entry.commitTo)
//                                         .foregroundColor(colorScheme == .dark ? .white : Color(.label))
//                                         .font(.subheadline)
//                                         .background(colorScheme == .dark ? Color.blue : Color.clear)
//                                         .padding(2)
//                                         .frame(minHeight: 60) // Two rows to start
//                                         .overlay(
//                                             RoundedRectangle(cornerRadius: 8)
//                                                 .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
//                                         )
//                                         .accessibilityLabel("Today I will")
//                                         .accessibilityHint("Enter what you commit to doing today")
//                                 }
                                
//                                 VStack(alignment: .leading, spacing: 4) {
//                                     Text("instead of...")
//                                         .padding(.leading, 16)
                                    
//                                     TextEditor(text: $entry.commitFrom)
//                                         .foregroundColor(colorScheme == .dark ? .white : Color(.label))
//                                         .font(.subheadline)
//                                         .background(colorScheme == .dark ? Color.blue : Color.clear)
//                                         .padding(2)
//                                         .frame(minHeight: 60) // Two rows to start
//                                         .overlay(
//                                             RoundedRectangle(cornerRadius: 8)
//                                                 .strokeBorder(Color(.systemGray2), lineWidth: 0.5)
//                                         )
//                                         .accessibilityLabel("Instead of")
//                                         .accessibilityHint("Enter what you're avoiding or replacing")
//                                 }
//                             }
//                         }
//         }
//         .onChange(of: entry.commitTo) { _, newValue in
//             // Check if morning focus is completed (both commit fields filled)
//             if !newValue.isEmpty && !entry.commitFrom.isEmpty {
//                 reminderManager.cancelMorningReminder()
//             }
//         }
//         .onChange(of: entry.commitFrom) { _, newValue in
//             // Check if morning focus is completed (both commit fields filled)
//             if !newValue.isEmpty && !entry.commitTo.isEmpty {
//                 reminderManager.cancelMorningReminder()
//             }
//         }
//     }
// }


// // MARK: - Custom Components

// struct StepCard<Content: View>: View {
//     let stepNumber: String
//     let accentColor: Color
//     let content: Content
//     @Environment(\.colorScheme) private var colorScheme
    
//     init(stepNumber: String, accentColor: Color, @ViewBuilder content: () -> Content) {
//         self.stepNumber = stepNumber
//         self.accentColor = accentColor
//         self.content = content()
//     }
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             HStack {
//                 Text(stepNumber)
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(colorScheme == .dark ? .black : accentColor)
                
//                 Spacer()
//             }
//             .padding(.bottom, 8)
            
//             content
//                 .padding(16)
//                 .background(
//                     RoundedRectangle(cornerRadius: 12)
//                         .fill(stepBackgroundColor)
//                         .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
//                 )
            
//             // Spacer between steps
//             Spacer()
//                 .frame(height: 16)
//         }
//     }
    
//     private var stepBackgroundColor: Color {
//         @Environment(\.colorScheme) var colorScheme
//         return colorScheme == .dark ? Color.leafGreen : Color.leafGreen.opacity(0.15)
//     }
// }

// struct CommitCard<Content: View>: View {
//     let content: Content
//     @Environment(\.colorScheme) private var colorScheme
    
//     init(@ViewBuilder content: () -> Content) {
//         self.content = content()
//     }
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             content
//                 .padding(20) // Extra padding for final step
//                 .background(
//                     RoundedRectangle(cornerRadius: 12)
//                         .fill(colorScheme == .dark ? Color.white : Color.blue.opacity(0.15)) // White in dark mode
//                         .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
//                 )
//         }
//     }
// }

// MARK: - SelectableTextEditor
struct SelectableTextEditor: UIViewRepresentable {
    @Binding var text: String
    let selectAllOnTap: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        
        // Add tap gesture to select all text
        if selectAllOnTap {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
            textView.addGestureRecognizer(tapGesture)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: SelectableTextEditor
        
        init(_ parent: SelectableTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            
            if !textView.text.isEmpty {
                // Select all text
                textView.selectAll(nil)
            } else {
                // Just focus the text view
                textView.becomeFirstResponder()
            }
        }
    }
}

#Preview {
    ScrollView {
        MorningFocusSection(entry: .constant(DailyEntry()))
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
