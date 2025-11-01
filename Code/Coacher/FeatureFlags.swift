//
//  FeatureFlags.swift
//  Coacher
//
//  Feature flags to control app functionality
//

import Foundation

/// Feature flags for controlling app behavior
struct FeatureFlags {
    /// Enable local LLM functionality (MLX/MLC models)
    /// Set to false to disable local AI options from UI
    static let useLocalLLM: Bool = false
    
    /// Enable coaching feature (currently behind "Coming Soon" overlay)
    static let enableCoaching: Bool = true
}
