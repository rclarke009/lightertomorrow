//
//  StreakHeatmap.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct StreakHeatmap: View {
    let entryDates: Set<Date>
    let weeksToShow: Int = 12
    
    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Build an array of weeks (Sun..Sat or Mon..Sun per locale)
        var result: [[Date]] = []
        let weekday = calendar.component(.weekday, from: today)
        let startOfThisWeek = calendar.date(byAdding: .day, value: -(weekday-1), to: today) ?? today
        
        for weekOffset in 0..<weeksToShow {
            let start = calendar.date(byAdding: .day, value: -(weekOffset * 7), to: startOfThisWeek)!
            let days = (0..<7).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: start)
            }
            result.append(days)
        }
        
        return result.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                    GridRow {
                        ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, day in
                            let isCompleted = entryDates.contains(day)
                            let isToday = Calendar.current.isDate(day, inSameDayAs: Date())
                            
                            Rectangle()
                                .fill(backgroundColor(for: day, isCompleted: isCompleted, isToday: isToday))
                                .frame(width: 12, height: 12)
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1)
                                )
                                .accessibilityLabel(Text(isCompleted ? "Completed" : "Not completed"))
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .cornerRadius(3)
                    Text("No activity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.teal)
                        .frame(width: 12, height: 12)
                        .cornerRadius(3)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 12, height: 12)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func backgroundColor(for date: Date, isCompleted: Bool, isToday: Bool) -> Color {
        if isCompleted {
            return .teal
        } else if isToday {
            return .blue.opacity(0.3)
        } else {
            return .gray.opacity(0.2)
        }
    }
}

#Preview {
    StreakHeatmap(entryDates: Set([
        Calendar.current.startOfDay(for: Date()),
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date())
    ]))
}
