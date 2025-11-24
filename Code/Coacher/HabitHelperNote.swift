//
//  HabitHelperNote.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class HabitHelperNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var step1_pattern: String
    var step4_rewire: String
    var completedAllSteps: Bool
    
    init(
        step1_pattern: String = "",
        step4_rewire: String = "",
        completedAllSteps: Bool = false
    ) {
        self.id = UUID()
        self.date = Date()
        self.step1_pattern = step1_pattern
        self.step4_rewire = step4_rewire
        self.completedAllSteps = completedAllSteps
    }
}
