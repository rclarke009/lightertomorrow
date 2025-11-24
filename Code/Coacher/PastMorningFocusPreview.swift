//
//  PastMorningFocusPreview.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct PastMorningFocusPreview: View {
    let offset: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Encouraging message
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("No data from \(formattedDate) - this is where you'll track your morning focus!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Read-only form structure
            VStack(alignment: .leading, spacing: 12) {
                Text("Morning Focus")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
                
                // Step 1 - My Why
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 1 – My Why")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text("Your personal motivation would appear here...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Step 2 - Identify a Challenge
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 2 – Identify a Challenge")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text("Select…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Step 3 - Choose My Swap
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 3 – Choose My Swap")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text("What healthier choice will I do instead?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Step 4 - Commit
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step 4 – Commit")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    Text("Today I will … instead of …")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("do this…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text("instead of")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("not this…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var formattedDate: String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        PastMorningFocusPreview(offset: -1)
        PastMorningFocusPreview(offset: -3)
    }
    .padding()
}
