//
//  TimeManager.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation

class TimeManager: ObservableObject {
    @Published var currentPhase: DayPhase = .day
    
    enum DayPhase {
        case day      // 00:00 - 17:59
        case evening  // 18:00 - 23:59
    }
    
    init() {
        updatePhase()
        // Update phase every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updatePhase()
        }
    }
    
    func updatePhase() {
        let hour = Calendar.current.component(.hour, from: Date())
        currentPhase = hour >= 18 ? .evening : .day
    }
    
    var isDayPhase: Bool {
        currentPhase == .day
    }
    
    var isEveningPhase: Bool {
        currentPhase == .evening
    }
    
    // Get the appropriate date for each section
    var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    var tomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayDate) ?? todayDate
    }
    
    var lastNightDate: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: todayDate) ?? todayDate
    }
    
    // Get appropriate greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "morning"
        case 12..<18:
            return "afternoon"
        default:
            return "evening"
        }
    }
}
