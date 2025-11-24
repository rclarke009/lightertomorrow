//
//  EmotionalTakeoverNote.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import Foundation
import SwiftData

@Model
final class EmotionalTakeoverNote {
    @Attribute(.unique) var id: UUID
    var date: Date
    var step2_bodySensation: String
    var step5_partNeed: String?
    var step6_nextTimePlan: String
    var completedAllSteps: Bool
    
    init(
        step2_bodySensation: String = "",
        step5_partNeed: String? = nil,
        step6_nextTimePlan: String = "",
        completedAllSteps: Bool = false
    ) {
        self.id = UUID()
        self.date = Date()
        self.step2_bodySensation = step2_bodySensation
        self.step5_partNeed = step5_partNeed
        self.step6_nextTimePlan = step6_nextTimePlan
        self.completedAllSteps = completedAllSteps
    }
}
