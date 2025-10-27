//
//  EveningPrepItem.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class EveningPrepItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isDefault: Bool // true for built-in items like "water bottle"
    var isEnabled: Bool // true if user wants to see this item
    var order: Int // for custom ordering
    var dateCreated: Date
    
    init(text: String, isDefault: Bool = false, order: Int = 0) {
        self.id = UUID()
        self.text = text
        self.isDefault = isDefault
        self.isEnabled = true
        self.order = order
        self.dateCreated = Date()
    }
}

// Extension to provide default prep items
extension EveningPrepItem {
    static func createDefaultItems() -> [EveningPrepItem] {
        return [
            EveningPrepItem(text: "Put sticky notes where I usually grab the less-healthy choice", isDefault: true, order: 0),
            EveningPrepItem(text: "Wash/cut veggies or fruit and place them at eye level", isDefault: true, order: 1),
            EveningPrepItem(text: "Put water bottle in fridge or by my bed", isDefault: true, order: 2), // Everyone needs water!
            EveningPrepItem(text: "Prep quick breakfast/snack", isDefault: true, order: 3)
        ]
    }
}
