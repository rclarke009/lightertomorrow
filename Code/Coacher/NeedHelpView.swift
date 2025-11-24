//
//  NeedHelpView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct NeedHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @State private var selectedType: CravingType?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Help hand")
                    .accessibilityHidden(false)
                
                Text("I Need Help")
                    .font(.largeTitle)
                    .bold()
                
                Text("What's happening right now?\nChoose the category that best describes your situation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            // Category Selection
            VStack(spacing: 16) {
                ForEach(CravingType.allCases) { type in
                    CategoryButton(type: type) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Cancel Button
            Button("Cancel", action: { dismiss() })
                .foregroundStyle(.secondary)
                .padding(.bottom)
                .accessibilityLabel("Cancel")
                .accessibilityHint("Closes help options and returns to previous screen")
        }
        .sheet(item: $selectedType) { type in
            MiniCoachView(type: type, onComplete: { cravingNote in
                saveCravingNote(cravingNote)
                dismiss()
            })
        }
    }
    
    private func saveCravingNote(_ note: CravingNote) {
        // Save on main queue to prevent SwiftData threading issues
        DispatchQueue.main.async {
            self.context.insert(note)
            
            do {
                try self.context.save()
                print("✅ Successfully saved craving note: \(note.type.displayName)")
                
                // Record activity for milestone tracking
                self.celebrationManager.recordActivity()
            } catch {
                print("❌ Failed to save craving note: \(error)")
            }
        }
    }
}

struct CategoryButton: View {
    let type: CravingType
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(type.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.displayName)
        .accessibilityHint(type.description)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NeedHelpView()
        .modelContainer(for: [DailyEntry.self, Achievement.self, LLMMessage.self, CravingNote.self, EmotionalTakeoverNote.self, HabitHelperNote.self], inMemory: true)
}
