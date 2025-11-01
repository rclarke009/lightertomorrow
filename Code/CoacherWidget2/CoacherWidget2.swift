//
//  CoacherWidget2.swift
//  CoacherWidget2
//
//  Created by Rebecca Clarke on 10/26/25.
//

import WidgetKit
import SwiftUI

//@main
//struct CoacherWidget2Bundle: WidgetBundle {
//    var body: some Widget {
//        CoacherWidget2()
//    }
//}

struct CoacherWidget2: Widget {
    let kind: String = "CoacherWidget2"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CoacherTimelineProvider()) { entry in
            CoacherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Coacher")
        .description("Quick access to I Need Help and I Did Great! features.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CoacherWidgetEntryView: View {
    var entry: CoacherTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    private var backgroundColor: Color {
        if family == .systemLarge {
            // Light blue in light mode for large widget specifically
            return colorScheme == .light ? Color(red: 0.545, green: 0.796, blue: 0.902) : Color.widgetBackground
        } else {
            return Color.widgetBackground
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(backgroundColor, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    CoacherWidget2()
} timeline: {
    CoacherTimelineEntry(
        date: .now,
        encouragingPrompt: "You've got this!",
        morningFocusCompleted: false,
        successNotesToday: 0,
        morningWhy: "",
        morningIdentity: "",
        morningFocus: "",
        morningStressResponse: ""
    )
}

#Preview(as: .systemMedium) {
    CoacherWidget2()
} timeline: {
    CoacherTimelineEntry(
        date: .now,
        encouragingPrompt: "Small steps add up!",
        morningFocusCompleted: true,
        successNotesToday: 2,
        morningWhy: "I want to feel healthy and energetic",
        morningIdentity: "I am someone who takes care of myself",
        morningFocus: "Today I will drink water and take breaks",
        morningStressResponse: "If I feel stressed, I will take 3 deep breaths"
    )
}

#Preview(as: .systemLarge) {
    CoacherWidget2()
} timeline: {
    CoacherTimelineEntry(
        date: .now,
        encouragingPrompt: "Your future self will thank you!",
        morningFocusCompleted: true,
        successNotesToday: 1,
        morningWhy: "I want to feel healthy and energetic throughout the day",
        morningIdentity: "I am someone who takes care of myself with kindness",
        morningFocus: "Today I will drink water regularly and take mindful breaks",
        morningStressResponse: "If I feel stressed, I will take 3 deep breaths and step outside for fresh air"
    )
}
