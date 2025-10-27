//
//  CravingNote.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CravingNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: CravingType
    var text: String
    var keptAudio: Bool
    var audioURL: URL?
    
    init(type: CravingType = .other, text: String = "", keptAudio: Bool = false, audioURL: URL? = nil) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.text = text
        self.keptAudio = keptAudio
        self.audioURL = audioURL
    }
}

enum CravingType: String, Codable, CaseIterable, Identifiable {
    case stress = "stress"
    case habit = "habit"
    case physical = "physical"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .stress: return "Stress / Emotional"
        case .habit: return "Habit / Automatic"
        case .physical: return "Physical / Biological"
        case .other: return "Other / Not Sure"
        }
    }
    
    var description: String {
        switch self {
        case .stress: return "Feeling overwhelmed, anxious, or emotionally triggered"
        case .habit: return "Automatic behavior, time/place triggers, or routine"
        case .physical: return "Hunger, thirst, tiredness, or physical need"
        case .other: return "Not sure what's causing this craving"
        }
    }
    
    var icon: String {
        switch self {
        case .stress: return "brain.head.profile"
        case .habit: return "repeat.circle"
        case .physical: return "heart.fill"
        case .other: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .stress: return .orange
        case .habit: return .blue
        case .physical: return .green
        case .other: return .gray
        }
    }
}
