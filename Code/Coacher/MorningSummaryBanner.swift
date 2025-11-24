//
//  MorningSummaryBanner.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct MorningSummaryBanner: View {
    let prepItems: [String]
    
    var body: some View {
        if !prepItems.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Night's Prep")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(prepItems, id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text(item)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemPurple).opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(.systemPurple).opacity(0.2), lineWidth: 0.5)
            )
        } else {
            HStack {
                Image(systemName: "moon.slash")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("No prep was done last night")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // With prep items
        MorningSummaryBanner(prepItems: ["Veggies prepped", "Water ready", "Breakfast planned"])
        
        // Without prep items
        MorningSummaryBanner(prepItems: [])
    }
    .padding()
}
