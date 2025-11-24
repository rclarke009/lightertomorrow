//
//  TonightBucket.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI
import SwiftData

struct TonightBucket: View {
    let entries: [DailyEntry]
    @Binding var entryToday: DailyEntry
    @Binding var hasUnsavedChanges: Bool
    let onCelebrationTrigger: (String, String) -> Void
    
    @State private var endOfDayCollapsed = false
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tonight")
                .font(.title3.weight(.semibold))
            
            SectionCard(
                title: "End-of-Day Check-In",
                icon: "checkmark.seal.fill",
                accent: .teal,
                collapsed: $endOfDayCollapsed
            ) {
                CareFirstEndOfDaySection(entry: $entryToday, onCelebrationTrigger: onCelebrationTrigger, scrollProxy: nil)
                    .onChange(of: entryToday.didCareAction) { _, _ in hasUnsavedChanges = true }
                    .onChange(of: entryToday.whatHelpedCalm) { _, _ in hasUnsavedChanges = true }
                    .onChange(of: entryToday.comfortEatingMoment) { _, _ in hasUnsavedChanges = true }
                    .onChange(of: entryToday.smallWinsForTomorrow) { _, _ in hasUnsavedChanges = true }
            }
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    TonightBucket(
        entries: [],
        entryToday: .constant(DailyEntry()),
        hasUnsavedChanges: .constant(false),
        onCelebrationTrigger: { _, _ in }
    )
    .padding()
}
