//
//  LLMMessage.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class LLMMessage {
    @Attribute(.unique) var id: UUID
    var role: Role
    var content: String
    var timestamp: Date
    
    init(role: Role, content: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum Role: String, Codable, CaseIterable, Identifiable {
    case user, assistant, system
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Coach"
        case .system: return "System"
        }
    }
    
    var isUser: Bool { self == .user }
    var isAssistant: Bool { self == .assistant }
    var isSystem: Bool { self == .system }
}
