//
//  Color+Extensions.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

extension Color {
    // MARK: - Brand Colors (Static - consistent across modes)
    static let brandBlue = Color(hex: "0C2F89")
    static let leafGreen = Color(hex: "5CB85C")
    static let leafYellow = Color(hex: "FFD54F")
    static let brightYellow = Color(hex: "FFC107")
    static let stressOrange = Color(hex: "FF8C00")
    static let helpButtonBlue = Color(hex: "4DA6FF")
    static let brightBlue = Color(hex: "007AFF")
    
    // MARK: - App Background Colors (Dynamic)
    static let appBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray6 : UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
    })
    
    // MARK: - Widget Background Colors (Dynamic)
    static let widgetBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
    })
    
    // MARK: - Widget Text Colors (Dynamic)
    static let widgetText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.label
    })
    
    static let widgetSecondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor.secondaryLabel
    })
    
    // MARK: - Card Background Colors (Dynamic)
    static let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.white
    })
    
    // MARK: - Text Colors (Dynamic - following Apple's semantic approach)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // MARK: - Morning Focus Card Colors (Preserved - your beautiful existing colors)
    static let morningFocusBackground = Color(UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(red: 0.30, green: 0.65, blue: 1.0, alpha: 1.0) // #4DA6FF - same as help button
        } else {
            return UIColor(red: 0.72, green: 0.88, blue: 0.94, alpha: 1.0) // #b8e0f0
        }
    })
    
    // MARK: - Semantic Colors (Dynamic)
    static let success = leafGreen
    static let highlight = leafYellow
    static let primary = brandBlue
    
    // MARK: - Legacy Support (for backward compatibility)
    static let dynamicBackground = Color(.systemBackground)
    static let dynamicCardBackground = Color(.secondarySystemBackground)
    static let dynamicText = Color(.label)
    static let dynamicSecondaryText = Color(.secondaryLabel)
    
    // MARK: - Coach Screen Colors (Legacy - now using appBackground)
    static let coachBackgroundLight = Color(hex: "E6F3FF")
    static let coachBackgroundDark = Color.black
    static let coachBackground = appBackground
    
    // MARK: - Dark Mode Specific Colors
    static let darkTextInputBackground = Color(hex: "2C2C2E")
    static let darkTextInputText = Color.white
    static let brightMorningFocusBlue = Color(hex: "00BFFF")
    static let brightMorningFocusText = Color.white
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
