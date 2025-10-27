//
//  CoacherComplicationProvider.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import ClockKit
import SwiftUI

class CoacherComplicationProvider: CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func complicationDescriptors(activeDescriptors: [CLKComplicationDescriptor]) async -> [CLKComplicationDescriptor] {
        return [
            CLKComplicationDescriptor(
                identifier: "coacher",
                displayName: "Coacher",
                supportedFamilies: [
                    .graphicCircular,
                    .graphicCorner,
                    .modularSmall,
                    .circularSmall
                ]
            )
        ]
    }
    
    // MARK: - Timeline Population
    
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        let template = getTemplate(for: complication)
        
        return CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
    }
    
    func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry] {
        return [await currentTimelineEntry(for: complication)].compactMap { $0 }
    }
    
    // MARK: - Placeholder
    
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        return getTemplate(for: complication)
    }
    
    // MARK: - Template Creation
    
    private func getTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularView(
                CoacherComplicationCircular()
            )
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackView(
                CoacherComplicationCorner()
            )
        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(
                textProvider: CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "🌱"),
                fillFraction: 0.5,
                ringStyle: .closed
            )
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(
                textProvider: CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "🌱"),
                fillFraction: 0.5,
                ringStyle: .closed
            )
        default:
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: CLKTextProvider.localizableTextProvider(withStringsFileTextKey: "Coacher")
            )
        }
    }
}

// MARK: - Complication Views

struct CoacherComplicationCircular: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3))
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)
        }
    }
}

struct CoacherComplicationCorner: View {
    var body: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            Text("Coacher")
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

