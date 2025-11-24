//
//  PastNightPrepPreview.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct PastNightPrepPreview: View {
    let offset: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Encouraging message
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("No data from \(formattedDate) - this is where you'll track your evening prep!")
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
        PastNightPrepPreview(offset: -1)
        PastNightPrepPreview(offset: -3)
    }
    .padding()
}
