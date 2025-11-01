//
//  Achievement.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateEarned: Date
    var type: String // e.g., "streak", "consistency", "first_week"
    var details: String
    
    init(name: String, dateEarned: Date = Date(), type: String, details: String = "") {
        self.id = UUID()
        self.name = name
        self.dateEarned = dateEarned
        self.type = type
        self.details = details
    }
    
    // Convenience initializers for common achievement types
    static func streakAchievement(days: Int) -> Achievement {
        let name: String
        let type = "streak"
        let details = "Maintained a \(days)-day streak"
        
        switch days {
        case 3: name = "Getting Started"
        case 7: name = "Week Warrior"
        case 14: name = "Fortnight Fighter"
        case 30: name = "Monthly Master"
        case 100: name = "Century Club"
        default: name = "\(days)-Day Streak"
        }
        
        return Achievement(name: name, type: type, details: details)
    }
    
    static func consistencyAchievement(daysThisWeek: Int) -> Achievement {
        let name = "Weekly Consistency"
        let type = "consistency"
        let details = "Completed \(daysThisWeek) out of 7 days this week"
        return Achievement(name: name, type: type, details: details)
    }
    
    static func firstWeekAchievement() -> Achievement {
        let name = "First Week Complete"
        let type = "first_week"
        let details = "Completed your first full week of Morning Focus"
        return Achievement(name: name, type: type, details: details)
    }
}
