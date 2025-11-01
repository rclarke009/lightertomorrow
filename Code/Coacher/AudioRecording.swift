//
//  AudioRecording.swift
//  Coacher
//
//  Created by Rebecca Clarke on 9/1/25.
//

import Foundation
import SwiftData

@Model
final class AudioRecording {
    @Attribute(.unique) var id: UUID
    var date: Date
    var transcription: String
    var type: CravingType?
    var duration: TimeInterval

    init(transcription: String, type: CravingType? = nil, duration: TimeInterval = 0) {
        self.id = UUID()
        self.date = Date()
        self.transcription = transcription
        self.type = type
        self.duration = duration
    }
}
