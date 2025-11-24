//
//  WidgetEntry.swift
//  CoacherWidget
//
//  Created by Rebecca Clarke on 8/30/25.
//

import WidgetKit
import Foundation

struct CoacherTimelineEntry: TimelineEntry {
    let date: Date
    let encouragingPrompt: String
    let morningFocusCompleted: Bool
    let successNotesToday: Int
    let morningWhy: String
    let morningIdentity: String
    let morningFocus: String
    let morningStressResponse: String
}
