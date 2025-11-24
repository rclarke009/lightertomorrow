//
//  LastNightPrepReviewView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct LastNightPrepReviewView: View {
    let entry: DailyEntry?
    
    var body: some View {
        if let entry = entry {
            VStack(alignment: .leading, spacing: 12) {
                // Night Prep checklist review
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: entry.stickyNotes ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.stickyNotes ? .green : .secondary)
                        Text("Put sticky notes where I usually grab the less-healthy choice")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: entry.preppedProduce ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.preppedProduce ? .green : .secondary)
                        Text("Wash/cut veggies or fruit and place them at eye level")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: entry.waterReady ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.waterReady ? .green : .secondary)
                        Text("Put water bottle in fridge or by my bed")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: entry.breakfastPrepped ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.breakfastPrepped ? .green : .secondary)
                        Text("Prep quick breakfast/snack")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Other notes
                if !entry.nightOther.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Other:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.nightOther)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Encouraging message
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("No prep was done last night - this is where you'll see your evening prep!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Read-only form structure preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Night Prep")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                            Text("Put sticky notes where I usually grab the less-healthy choice")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                            Text("Wash/cut veggies or fruit and place them at eye level")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                            Text("Put water bottle in fridge or by my bed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                            Text("Prep quick breakfast/snack")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Other…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With prep data
        LastNightPrepReviewView(entry: {
            let entry = DailyEntry()
            entry.stickyNotes = true
            entry.preppedProduce = true
            entry.waterReady = false
            entry.breakfastPrepped = true
            entry.nightOther = "Set out workout clothes for morning"
            return entry
        }())
        
        // Without prep data
        LastNightPrepReviewView(entry: nil)
    }
    .padding()
}
