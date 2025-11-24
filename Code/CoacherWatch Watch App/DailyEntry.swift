//
//  DailyEntry.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class DailyEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    // Night Prep
    var stickyNotes: Bool
    var preppedProduce: Bool
    var waterReady: Bool
    var breakfastPrepped: Bool
    var nightOther: String
    
    // Track which default prep items are hidden/deleted
    var hiddenDefaultPrepItems: [String]?
    
    // New flexible evening prep system
    var eveningPrepItems: [EveningPrepItem]?
    var customPrepItems: [String]? // All custom prep items (regardless of completion status)
    var completedCustomPrepItems: [String]? // Track which custom prep items were completed today
    
    // Morning Focus - Care-First Approach
    // Step 1: Why This Matters
    var whyThisMatters: String  // "I want to feel healthy and energetic..."
    
    // Step 2: Identity Statement
    var identityStatement: String?  // "I am someone who..."
    
    // Step 3: Today's Focus
    var todaysFocus: String  // "Today I will care for myself by..."
    
    // Step 4: Stress Response Plan
    var stressResponse: String  // "If I feel stressed... I will..."
    var optionalSupportiveSnack: String  // Optional supportive snack after stress response
    
    // Legacy fields for backward compatibility (will be deprecated)
    var myWhy: String
    var challenge: Challenge
    var challengeOther: String
    var chosenSwap: String
    var commitFrom: String   // instead of ___
    var commitTo: String     // Today I will ___ instead of ___
    
    // End of Day - Care-First Approach
    // Step 1: Celebrate Showing Up
    var didCareAction: Bool?  // Did you do your care action at least once?
    
    // Step 2: Gentle Reflection
    var whatHelpedCalm: String  // What helped you feel calm or cared for today?
    var comfortEatingMoment: String?  // What pulled you toward comfort eating?
    
    // Step 2.5: Morning Focus Reflection (only for users with morning focus)
    var morningFocusHelped: Bool?  // Did this morning's focus help?
    var whatElseCouldHelp: String?  // If focus didn't help, what else might work?
    
    // Step 3: Prep Small Wins for Tomorrow
    var smallWinsForTomorrow: String  // One small thing to set up for Future You
    
    // Legacy fields for backward compatibility
    var followedSwap: Bool?
    var feelAboutIt: String
    var whatGotInTheWay: String
    
    // Voice notes (file URLs in app sandbox)
    var voiceNotes: [URL]?
    
    // Craving notes for "I Need Help" flow
    var cravingNotes: [CravingNote]?
    
    init() {
        self.id = UUID()
        self.date = Date()
        self.stickyNotes = false
        self.preppedProduce = false
        self.waterReady = false
        self.breakfastPrepped = false
        self.nightOther = ""
        self.hiddenDefaultPrepItems = nil
        self.eveningPrepItems = nil
        self.customPrepItems = nil
        self.completedCustomPrepItems = nil
        
        // New care-first fields
        self.whyThisMatters = ""
        self.identityStatement = nil
        self.todaysFocus = ""
        self.stressResponse = ""
        self.optionalSupportiveSnack = ""
        self.didCareAction = nil
        self.whatHelpedCalm = ""
        self.comfortEatingMoment = nil
        self.morningFocusHelped = nil
        self.whatElseCouldHelp = nil
        self.smallWinsForTomorrow = ""
        
        // Legacy fields
        self.myWhy = ""
        self.challenge = Challenge.none
        self.challengeOther = ""
        self.chosenSwap = ""
        self.commitFrom = ""
        self.commitTo = ""
        self.followedSwap = nil
        self.feelAboutIt = ""
        self.whatGotInTheWay = ""
        self.voiceNotes = nil
        self.cravingNotes = nil
    }
    
    // Computed properties for convenience
    var hasAnyNightPrep: Bool {
        stickyNotes || preppedProduce || waterReady || breakfastPrepped || !nightOther.isEmpty
    }
    
    var hasAnyMorningFocus: Bool {
        // Check new care-first fields first
        !whyThisMatters.isEmpty || (identityStatement?.isEmpty == false) || !todaysFocus.isEmpty || !stressResponse.isEmpty || 
        // Fall back to legacy fields for backward compatibility
        !myWhy.isEmpty || challenge != .none || !chosenSwap.isEmpty || !commitTo.isEmpty || !commitFrom.isEmpty
    }
    
    var morningFlowCompletedToday: Bool {
        // Check if all required morning flow fields are filled and entry is from today
        let today = Calendar.current.startOfDay(for: Date())
        let entryDate = Calendar.current.startOfDay(for: date)
        
        return entryDate == today && 
               !whyThisMatters.isEmpty && 
               (identityStatement?.isEmpty == false) && 
               !todaysFocus.isEmpty && 
               !stressResponse.isEmpty
    }
    
    var hasAnyEndOfDay: Bool {
        // Check new care-first fields first
        didCareAction != nil || !whatHelpedCalm.isEmpty || (comfortEatingMoment?.isEmpty == false) || !smallWinsForTomorrow.isEmpty ||
        // Fall back to legacy fields for backward compatibility
        followedSwap != nil || !feelAboutIt.isEmpty || !whatGotInTheWay.isEmpty
    }
    
    var hasAnyAction: Bool {
        hasAnyNightPrep || hasAnyMorningFocus || hasAnyEndOfDay
    }
    
    // Helper computed properties for optional arrays
    var safeEveningPrepItems: [EveningPrepItem] {
        eveningPrepItems ?? []
    }
    
    var safeCustomPrepItems: [String] {
        customPrepItems ?? []
    }
    
    var safeCompletedCustomPrepItems: [String] {
        completedCustomPrepItems ?? []
    }
    
    var safeVoiceNotes: [URL] {
        voiceNotes ?? []
    }
    
    var safeCravingNotes: [CravingNote] {
        cravingNotes ?? []
    }
    
    var safeHiddenDefaultPrepItems: [String] {
        hiddenDefaultPrepItems ?? []
    }
    
    // MARK: - Array Management Helpers
    func ensureArraysInitialized() {
        if eveningPrepItems == nil {
            eveningPrepItems = []
        }
        if customPrepItems == nil {
            customPrepItems = []
        }
        if completedCustomPrepItems == nil {
            completedCustomPrepItems = []
        }
        if hiddenDefaultPrepItems == nil {
            hiddenDefaultPrepItems = []
        }
        if voiceNotes == nil {
            voiceNotes = []
        }
        if cravingNotes == nil {
            cravingNotes = []
        }
    }
}



enum Challenge: String, Codable, CaseIterable, Identifiable {
    case none, skippingMeals, lateNightSnacking, sugaryDrinks, onTheGo, emotionalEating, other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "Select..."
        case .skippingMeals: return "Skipping meals"
        case .lateNightSnacking: return "Late-night snacking"
        case .sugaryDrinks: return "Sugary drinks"
        case .onTheGo: return "Eating on the go / fast food"
        case .emotionalEating: return "Emotional eating"
        case .other: return "Other"
        }
    }
}
