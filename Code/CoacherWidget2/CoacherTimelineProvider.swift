//
//  CoacherTimelineProvider.swift
//  CoacherWidget
//
//  Created by Rebecca Clarke on 8/30/25.
//

import WidgetKit
import SwiftData
import Foundation

struct CoacherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoacherTimelineEntry {
        CoacherTimelineEntry(
            date: Date(),
            encouragingPrompt: context.family == .systemSmall ? "Winner!" : "You've got this today!",
            morningFocusCompleted: false,
            successNotesToday: 0,
            morningWhy: "",
            morningIdentity: "",
            morningFocus: "",
            morningStressResponse: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CoacherTimelineEntry) -> ()) {
        let entry = CoacherTimelineEntry(
            date: Date(),
            encouragingPrompt: context.family == .systemSmall ? "Champion!" : "Small steps add up!",
            morningFocusCompleted: true,
            successNotesToday: 2,
            morningWhy: "I want to feel healthy and energetic",
            morningIdentity: "I am someone who takes care of myself",
            morningFocus: "Today I will drink water and take breaks",
            morningStressResponse: "If I feel stressed, I will take 3 deep breaths"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoacherTimelineEntry>) -> ()) {
        Task {
            let currentDate = Date()
            let entry = await fetchWidgetData(for: currentDate, widgetFamily: context.family)
            
            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchWidgetData(for date: Date, widgetFamily: WidgetFamily) async -> CoacherTimelineEntry {
        let encouragingPrompts: [String]
        
        // Use different prompts based on widget size
        switch widgetFamily {
        case .systemSmall:
            encouragingPrompts = [
                "Winner!",
                "Champion!",
                "Go for it!",
                "You rock!",
                "Amazing!",
                "Keep going!",
                "You've got this!",
                "Stay strong!",
                "Believe!",
                "Rise up!"
            ]
        default:
            encouragingPrompts = [
                "You've got this today!",
                "Small steps add up",
                "Your future self will thank you",
                "Progress, not perfection",
                "You're stronger than you think",
                "One choice at a time",
                "You're doing great",
                "Keep showing up"
            ]
        }
        
        // Rotate prompt based on day of year
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let promptIndex = dayOfYear % encouragingPrompts.count
        let selectedPrompt = encouragingPrompts[promptIndex]
        
        // Read real data from UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.coacher.shared") ?? UserDefaults.standard
        
        // Check if morning focus was completed today
        let morningFocusCompletedDate = userDefaults.object(forKey: "morningCompletedDate") as? Date
        let morningFocusCompleted = Calendar.current.isDate(morningFocusCompletedDate ?? Date.distantPast, inSameDayAs: date)
        
        // Get morning focus data if completed
        let morningWhy = morningFocusCompleted ? (userDefaults.string(forKey: "morningWhy") ?? "") : ""
        let morningIdentity = morningFocusCompleted ? (userDefaults.string(forKey: "morningIdentity") ?? "") : ""
        let morningFocus = morningFocusCompleted ? (userDefaults.string(forKey: "morningFocus") ?? "") : ""
        let morningStressResponse = morningFocusCompleted ? (userDefaults.string(forKey: "morningStressResponse") ?? "") : ""
        
        // Count success notes for today
        let successNotesToday = userDefaults.integer(forKey: "successNotesToday")
        
        return CoacherTimelineEntry(
            date: date,
            encouragingPrompt: selectedPrompt,
            morningFocusCompleted: morningFocusCompleted,
            successNotesToday: successNotesToday,
            morningWhy: morningWhy,
            morningIdentity: morningIdentity,
            morningFocus: morningFocus,
            morningStressResponse: morningStressResponse
        )
    }}
