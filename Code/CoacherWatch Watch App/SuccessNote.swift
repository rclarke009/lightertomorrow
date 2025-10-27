//
//  SuccessNote.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class SuccessNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: SuccessType
    var text: String
    var keptAudio: Bool
    var audioURL: URL?
    
    init(type: SuccessType = .choice, text: String = "", keptAudio: Bool = false, audioURL: URL? = nil) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.text = text
        self.keptAudio = keptAudio
        self.audioURL = audioURL
    }
}

enum SuccessType: String, Codable, CaseIterable, Identifiable {
    case choice = "choice"
    case prep = "prep"
    case habit = "habit"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .choice: return "Great Choice"
        case .prep: return "Prepared something ahead"
        case .habit: return "Habit Win"
        case .other: return "Other Success"
        }
    }
    
    var description: String {
        switch self {
        case .choice: return "Made a healthier choice"
        case .prep: return "Prepared something that set you up for success"
        case .habit: return "Stuck to a good habit or routine"
        case .other: return "Any other win or positive moment"
        }
    }
    
    var icon: String {
        switch self {
        case .choice: return "checkmark.circle.fill"
        case .prep: return "moon.stars.fill"
        case .habit: return "repeat.circle.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .choice: return .green
        case .prep: return .blue
        case .habit: return .purple
        case .other: return .orange
        }
    }
}
