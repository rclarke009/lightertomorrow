//
//  UserSettings.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var customEveningPrepItems: [String]
    var dateCreated: Date
    var lastModified: Date
    
    init() {
        self.id = UUID()
        self.customEveningPrepItems = []
        self.dateCreated = Date()
        self.lastModified = Date()
    }
    
    func addCustomItem(_ item: String) {
        print("🔍 DEBUG: UserSettings.addCustomItem called with: '\(item)'")
        print("🔍 DEBUG: UserSettings - Before adding: \(customEveningPrepItems.count) items")
        
        if !customEveningPrepItems.contains(item) {
            customEveningPrepItems.append(item)
            lastModified = Date()
            print("🔍 DEBUG: UserSettings - After adding: \(customEveningPrepItems.count) items")
            print("🔍 DEBUG: UserSettings - Items array: \(customEveningPrepItems)")
        } else {
            print("🔍 DEBUG: UserSettings - Item already exists, not adding")
        }
    }
    
    func removeCustomItem(_ item: String) {
        print("🔍 DEBUG: UserSettings.removeCustomItem called with: '\(item)'")
        print("🔍 DEBUG: UserSettings - Before removing: \(customEveningPrepItems.count) items")
        
        customEveningPrepItems.removeAll { $0 == item }
        lastModified = Date()
        
        print("🔍 DEBUG: UserSettings - After removing: \(customEveningPrepItems.count) items")
        print("🔍 DEBUG: UserSettings - Items array: \(customEveningPrepItems)")
    }
    
    func removeCustomItems(_ items: [String]) {
        print("🔍 DEBUG: UserSettings.removeCustomItems called with: \(items)")
        print("🔍 DEBUG: UserSettings - Before removing: \(customEveningPrepItems.count) items")
        
        customEveningPrepItems.removeAll { items.contains($0) }
        lastModified = Date()
        
        print("🔍 DEBUG: UserSettings - After removing: \(customEveningPrepItems.count) items")
        print("🔍 DEBUG: UserSettings - Items array: \(customEveningPrepItems)")
    }
}
