import SwiftUI
import Foundation

class CelebrationManager: ObservableObject {
    @AppStorage("showAnimations") private var showAnimations: Bool = true
    
    @Published var showingMilestoneCelebration = false
    @Published var milestoneStreakCount = 0
    @Published var milestoneMessage = ""
    
    // New three-tier celebration system
    @Published var showingTinyCelebration = false
    @Published var showingMediumCelebration = false
    @Published var showingBigCelebration = false
    @Published var celebrationMessage = ""
    @Published var celebrationType: CelebrationType = .tiny
    
    // Rate limiting for celebrations
    private var lastTinyCelebration: Date = Date.distantPast
    private var lastMediumCelebration: Date = Date.distantPast
    private var lastBigCelebration: Date = Date.distantPast
    private var tinyCelebrationCount = 0
    private var mediumCelebrationCount = 0
    private var bigCelebrationCount = 0
    
    private let streakManager = StreakManager()
    
    enum CelebrationType {
        case tiny, medium, big
    }
    
    // Encouraging phrases for regular celebrations
    private let encouragingPhrases = [
        "One healthier choice, done.",
        "That swap makes you stronger.",
        "Small steps, big wins.",
        "You're building momentum!",
        "Every choice counts!",
        "Growing healthier habits!",
        "Great job staying on track!",
        "You're making progress!",
        "Little swaps, lasting change.",
        "Another brick in your strong foundation.",
        "Tiny steps grow into giant leaps.",
        "You chose health today.",
        "That's how habits are built—one choice.",
        "Momentum is on your side.",
        "Keep stacking wins like this.",
        "Today's choice shapes tomorrow's you.",
        "You're proving it's possible.",
        "That swap is a gift to your future self.",
        "Onward and upward!",
        "Next stop: a healthier you",
        "You're leveling up!",
        "Ka-ching! Another win.",
        "Your future self just high-fived you",
        "Momentum unlocked!",
        "That's how champions roll."
    ]
    
    // Personalized encouraging phrases (used ~10% of the time)
    private let personalizedPhrases = [
        "Way to go, {name}!",
        "You're crushing it, {name}!",
        "Keep it up, {name}!",
        "That's the spirit, {name}!",
        "You've got this, {name}!",
        "Amazing work, {name}!",
        "You're on fire, {name}!",
        "Rock star move, {name}!",
        "You're unstoppable, {name}!",
        "Fantastic choice, {name}!"
    ]
    
    // Get the streak manager for external access
    var streakTracker: StreakManager {
        return streakManager
    }
    
    var animationsEnabled: Bool {
        get { showAnimations }
        set { 
            showAnimations = newValue
            objectWillChange.send()
        }
    }
    
    func randomEncouragingPhrase() -> String {
        // Use personalized messages ~10% of the time
        if Int.random(in: 1...10) == 1 {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            if !userName.isEmpty {
                let personalizedPhrase = personalizedPhrases.randomElement() ?? personalizedPhrases[0]
                return personalizedPhrase.replacingOccurrences(of: "{name}", with: userName)
            }
        }
        
        // Use regular encouraging phrases 90% of the time
        return encouragingPhrases.randomElement() ?? encouragingPhrases[0]
    }
    
    func shouldCelebrate() -> Bool {
        return true // Always show celebration text
    }
    
    // Check for milestone celebrations
    func checkForMilestoneCelebration() {
        if streakManager.shouldCelebrateMilestone() {
            milestoneStreakCount = streakManager.streak
            milestoneMessage = streakManager.milestoneQuote() ?? "Amazing achievement!"
            showingMilestoneCelebration = true
            
            // Mark milestone as celebrated
            streakManager.markMilestoneCelebrated()
        }
    }
    
    // Record activity and check for milestones
    func recordActivity() {
        streakManager.recordActivity()
        checkForMilestoneCelebration()
    }
    
    // Dismiss milestone celebration
    func dismissMilestoneCelebration() {
        showingMilestoneCelebration = false
    }
    
    // MARK: - New Three-Tier Celebration System
    
    // Warm validation messages for difficult days
    private let warmValidationMessages = [
        "That's okay—showing up here still counts. 🌱",
        "Not every day goes as planned, but you're still learning what you need.",
        "It makes sense today felt tough. You're not alone in that.",
        "Even noticing that urge or stress matters. Tomorrow's a fresh start.",
        "Showing up here still matters.",
        "Not every day is smooth, and that's okay.",
        "Even noticing today's challenge is progress.",
        "You don't have to be perfect to keep going.",
        "Every step back is also a chance to learn.",
        "This was a tough day, but you're not alone.",
        "You deserve kindness, especially when it feels hard.",
        "Caring for yourself includes patience on days like this.",
        "It's okay to rest. Tomorrow is a reset.",
        "Struggling doesn't erase your effort.",
        "Tomorrow is a fresh page.",
        "Even small attempts today set up tomorrow.",
        "Your future self is grateful you checked in.",
        "Each day is practice, not a test.",
        "Momentum comes from showing up, not perfection."
    ]
    
    // Celebration messages for successes
    private let tinyCelebrationMessages = [
        "You did it — that counts.",
        "A care action, done. 🌱",
        "Tiny steps, real progress.",
        "That's a win worth noticing.",
        "Consistency beats perfection."
    ]
    
    private let mediumCelebrationMessages = [
        "You're showing up as someone who cares for themselves.",
        "Every small act reinforces your new identity.",
        "This is how resilience is built.",
        "Proof you can keep promises to yourself.",
        "One step today = momentum tomorrow.",
        "Future you is already thankful.",
        "You've planted another seed.",
        "This is how streaks start.",
        "Your effort is adding up.",
        "Today you showed yourself you can."
    ]
    
    private let bigCelebrationMessages = [
        "Seven days in a row—amazing consistency!",
        "You've showed up on 5 days this week—your future self feels this.",
        "This is how champions roll!",
        "You're building something incredible!",
        "Momentum unlocked!",
        "That's how legends are made!",
        "You're absolutely crushing it!",
        "This is the stuff of champions!",
        "You're rewriting your story!",
        "This is how dreams become reality!"
    ]
    
    // Trigger celebrations based on the new care-first flow
    func triggerCelebration(for action: CelebrationAction) {
        print("🎉 DEBUG: triggerCelebration called for \(action), showAnimations: \(showAnimations)")
        guard showAnimations else { 
            print("🎉 DEBUG: Animations disabled, not showing celebration")
            return 
        }
        
        let now = Date()
        let timeSinceLastTiny = now.timeIntervalSince(lastTinyCelebration)
        let timeSinceLastMedium = now.timeIntervalSince(lastMediumCelebration)
        let timeSinceLastBig = now.timeIntervalSince(lastBigCelebration)
        
        // Rate limiting: max 1 medium and 1 big per session
        let canShowMedium = timeSinceLastMedium > 300 // 5 minutes
        let canShowBig = timeSinceLastBig > 300 // 5 minutes
        
        switch action {
        case .morningBreathDone:
            if timeSinceLastTiny > 60 { // 1 minute cooldown
                showTinyCelebration(message: tinyCelebrationMessages.randomElement() ?? "You did it — that counts.")
            }
            
        case .identityAndFocusCompleted:
            if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "Tiny steps, real progress.")
            }
            
        case .stressResponseDefined:
            if canShowMedium {
                showMediumCelebration(message: "This is how resilience is built.")
            } else if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "That's a win worth noticing.")
            }
            
        case .morningFlowCompleted:
            if canShowMedium {
                showMediumCelebration(message: "You're showing up as someone who cares for themselves.")
            } else if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "Tiny steps, real progress.")
            }
            
        case .careActionYes:
            if canShowMedium {
                showMediumCelebration(message: mediumCelebrationMessages.randomElement() ?? "You're showing up as someone who cares for themselves.")
            } else if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "A care action, done. 🌱")
            }
            
        case .multiplePrepsDone:
            if canShowMedium {
                showMediumCelebration(message: "Every small act reinforces your new identity.")
            } else if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "That's a win worth noticing.")
            }
            
        case .weeklyConsistencyBadge:
            if canShowBig {
                showBigCelebration(message: "You've showed up on 5 days this week—your future self feels this.")
            } else if canShowMedium {
                showMediumCelebration(message: "This is how streaks start.")
            }
            
        case .streakMilestone(let days):
            if days >= 7 && canShowBig {
                showBigCelebration(message: "Seven days in a row—amazing consistency!")
            } else if canShowMedium {
                showMediumCelebration(message: "This is how resilience is built.")
            }
            
        case .firstStressResponseEver:
            if canShowBig {
                showBigCelebration(message: "This is how champions roll!")
            } else if canShowMedium {
                showMediumCelebration(message: "This is how resilience is built.")
            }
            
        case .checklistItem:
            if timeSinceLastTiny > 30 { // 30 second cooldown for checklist items
                showTinyCelebration(message: "Future You will thank you!")
            }
            
        case .dayComplete:
            if canShowMedium {
                showMediumCelebration(message: "You showed up today.")
            } else if timeSinceLastTiny > 60 {
                showTinyCelebration(message: "You showed up today.")
            }
            
        case .firstBreathingDoneToday:
            if timeSinceLastTiny > 30 { // 30 second cooldown
                print("🎉 DEBUG: Showing first breathing celebration")
                showTinyCelebration(message: "Breathing complete — that counts.")
            } else {
                print("🎉 DEBUG: First breathing celebration on cooldown")
            }
        }
    }
    
    private func showTinyCelebration(message: String) {
        print("🎉 DEBUG: showTinyCelebration called with message: \(message)")
        celebrationType = .tiny
        celebrationMessage = message
        showingTinyCelebration = true
        lastTinyCelebration = Date()
        tinyCelebrationCount += 1
        print("🎉 DEBUG: showingTinyCelebration set to true")
    }
    
    private func showMediumCelebration(message: String) {
        celebrationType = .medium
        celebrationMessage = message
        showingMediumCelebration = true
        lastMediumCelebration = Date()
        mediumCelebrationCount += 1
    }
    
    private func showBigCelebration(message: String) {
        celebrationType = .big
        celebrationMessage = message
        showingBigCelebration = true
        lastBigCelebration = Date()
        bigCelebrationCount += 1
    }
    
    func dismissCelebration() {
        showingTinyCelebration = false
        showingMediumCelebration = false
        showingBigCelebration = false
    }
    
    func getWarmValidationMessage() -> String {
        return warmValidationMessages.randomElement() ?? "That's okay—showing up here still counts. 🌱"
    }
    
    func getCelebrationMessage(for success: Bool) -> String {
        if success {
            return mediumCelebrationMessages.randomElement() ?? "You're showing up as someone who cares for themselves."
        } else {
            return getWarmValidationMessage()
        }
    }
}

// MARK: - Celebration Actions
enum CelebrationAction {
    case morningBreathDone
    case identityAndFocusCompleted
    case stressResponseDefined
    case morningFlowCompleted
    case careActionYes
    case multiplePrepsDone
    case weeklyConsistencyBadge
    case streakMilestone(Int)
    case firstStressResponseEver
    case checklistItem
    case dayComplete
    case firstBreathingDoneToday
}
