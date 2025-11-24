//
//  UsageTracker.swift
//  Coacher
//
//  Tracks AI token usage with monthly limits and reset logic
//

import Foundation

/// Manages token usage tracking with monthly limits
@MainActor
class UsageTracker: ObservableObject {
    static let shared = UsageTracker()
    
    // UserDefaults keys
    private let tokensUsedKey = "usageTokensUsed"
    private let lastResetDateKey = "usageLastResetDate"
    private let warningShownKey = "usageWarningShownForMonth"
    
    // Configuration
    private let monthlyLimit: Int = 100_000 // 100k tokens per month
    private let warningThreshold: Double = 0.80 // 80% threshold
    
    @Published var currentUsage: Int = 0
    @Published var usagePercentage: Double = 0.0
    
    private init() {
        resetIfNeeded()
        loadCurrentUsage()
    }
    
    // MARK: - Public Methods
    
    /// Get current token usage
    func getCurrentUsage() -> Int {
        resetIfNeeded()
        loadCurrentUsage()
        return currentUsage
    }
    
    /// Check if a request can be made with the given token requirement
    func canMakeRequest(requiredTokens: Int = 0) -> Bool {
        resetIfNeeded()
        loadCurrentUsage()
        return (currentUsage + requiredTokens) <= monthlyLimit
    }
    
    /// Record token usage (input + output tokens)
    func recordUsage(inputTokens: Int, outputTokens: Int) {
        let totalTokens = inputTokens + outputTokens
        resetIfNeeded()
        
        let newUsage = currentUsage + totalTokens
        UserDefaults.standard.set(newUsage, forKey: tokensUsedKey)
        loadCurrentUsage()
        
        print("📊 UsageTracker: Recorded \(totalTokens) tokens (input: \(inputTokens), output: \(outputTokens)). Total: \(currentUsage)/\(monthlyLimit)")
    }
    
    /// Check if warning should be shown (80% threshold, once per month)
    func shouldShowWarning() -> Bool {
        resetIfNeeded()
        loadCurrentUsage()
        
        // Check if already shown this month
        let currentMonthKey = getCurrentMonthKey()
        let warningShownForMonth = UserDefaults.standard.string(forKey: warningShownKey)
        
        if warningShownForMonth == currentMonthKey {
            return false // Already shown this month
        }
        
        // Check if at or above 80% threshold
        let percentage = Double(currentUsage) / Double(monthlyLimit)
        return percentage >= warningThreshold
    }
    
    /// Mark warning as shown for current month
    func markWarningShown() {
        let currentMonthKey = getCurrentMonthKey()
        UserDefaults.standard.set(currentMonthKey, forKey: warningShownKey)
        print("📊 UsageTracker: Marked warning as shown for \(currentMonthKey)")
    }
    
    /// Get renewal date (first of next month)
    func getRenewalDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get first day of next month
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let firstOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            // Fallback: return first of next month as best guess
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        }
        
        return firstOfNextMonth
    }
    
    /// Get formatted renewal date string
    func getRenewalDateString() -> String {
        let date = getRenewalDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Get remaining tokens
    func getRemainingTokens() -> Int {
        return max(0, monthlyLimit - currentUsage)
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentUsage() {
        currentUsage = UserDefaults.standard.integer(forKey: tokensUsedKey)
        usagePercentage = Double(currentUsage) / Double(monthlyLimit)
    }
    
    private func resetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last reset date
        let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date
        
        // If no last reset date, set it to now (first time setup)
        guard let lastReset = lastResetDate else {
            UserDefaults.standard.set(now, forKey: lastResetDateKey)
            UserDefaults.standard.set(0, forKey: tokensUsedKey)
            currentUsage = 0
            usagePercentage = 0.0
            return
        }
        
        // Check if we've moved to a new month
        let lastMonth = calendar.component(.month, from: lastReset)
        let currentMonth = calendar.component(.month, from: now)
        let lastYear = calendar.component(.year, from: lastReset)
        let currentYear = calendar.component(.year, from: now)
        
        // Reset if month changed (or year changed)
        if currentMonth != lastMonth || currentYear != lastYear {
            print("📊 UsageTracker: Month changed - resetting usage. Previous: \(currentUsage) tokens")
            UserDefaults.standard.set(now, forKey: lastResetDateKey)
            UserDefaults.standard.set(0, forKey: tokensUsedKey)
            currentUsage = 0
            usagePercentage = 0.0
            
            // Clear warning flag for new month
            UserDefaults.standard.removeObject(forKey: warningShownKey)
        }
    }
    
    private func getCurrentMonthKey() -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return "\(year)-\(month)"
    }
    
    // MARK: - Testing/Reset (for development)
    
    /// Reset usage manually (for testing)
    func resetUsage() {
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        UserDefaults.standard.set(0, forKey: tokensUsedKey)
        UserDefaults.standard.removeObject(forKey: warningShownKey)
        loadCurrentUsage()
        print("📊 UsageTracker: Manually reset usage")
    }
    
    /// Set usage to a specific value (for testing)
    func setUsage(_ tokens: Int) {
        UserDefaults.standard.set(tokens, forKey: tokensUsedKey)
        loadCurrentUsage()
        print("📊 UsageTracker: Set usage to \(tokens)")
    }
}
