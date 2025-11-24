//
//  CoacherWidget2LiveActivity.swift
//  CoacherWidget2
//
//  Created by Rebecca Clarke on 10/26/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CoacherWidget2Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CoacherWidget2LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CoacherWidget2Attributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension CoacherWidget2Attributes {
    fileprivate static var preview: CoacherWidget2Attributes {
        CoacherWidget2Attributes(name: "World")
    }
}

extension CoacherWidget2Attributes.ContentState {
    fileprivate static var smiley: CoacherWidget2Attributes.ContentState {
        CoacherWidget2Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CoacherWidget2Attributes.ContentState {
         CoacherWidget2Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CoacherWidget2Attributes.preview) {
   CoacherWidget2LiveActivity()
} contentStates: {
    CoacherWidget2Attributes.ContentState.smiley
    CoacherWidget2Attributes.ContentState.starEyes
}
