//
//  SectionCard.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: SectionAccent
    @Binding var collapsed: Bool
    var dimmed: Bool = false
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        icon: String,
        accent: SectionAccent,
        collapsed: Binding<Bool>,
        dimmed: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accent = accent
        self._collapsed = collapsed
        self.dimmed = dimmed
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (non-tappable area)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(headerForeground)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(headerForeground)
                
                Spacer()
                
                // Chevron is the ONLY tappable control
                Button(action: { 
                    print("DEBUG: Chevron button tapped! Current collapsed state: \(collapsed)")
                    withAnimation(.snappy) { 
                        collapsed.toggle() 
                    }
                    print("DEBUG: After toggle, collapsed state: \(collapsed)")
                }) {
                    Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .frame(width: 20, height: 20) // minimal size
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(collapsed ? "Expand section" : "Collapse section")
                .accessibilityHint(collapsed ? "Shows the section content" : "Hides the section content")
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(headerBackground)
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            // DEBUG: Removed highPriorityGesture to see if it's interfering

            // Content integrated into the same card background
            if !collapsed {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(14) // Add padding back for all accents
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(headerBackground)
        ) // Single background for entire card
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .overlay( // dim whole card if "past"
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity((accent == .blue || accent == .teal) ? 0 : (dimmed ? 0.05 : 0)))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }

    // MARK: - Colors
    private var headerBackground: AnyShapeStyle {
        switch accent {
        case .blue:
            return AnyShapeStyle(
                colorScheme == .dark ? 
                Color.helpButtonBlue.gradient :
                Color(hex: "b8e0f0").gradient
            )
        case .purple:
            return AnyShapeStyle(Color.brandBlue.opacity(0.12).gradient)
        case .teal:
            return AnyShapeStyle(
                colorScheme == .dark ? 
                Color.leafGreen.gradient :
                Color.leafGreen.gradient
            )
        case .goldenYellow:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.brandBlue.opacity(0.2), Color.brandBlue.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            ))
        case .dimmedGreen:
            return AnyShapeStyle(Color.leafGreen.opacity(0.2).gradient)
        case .gray:
            return AnyShapeStyle(Color.dynamicSecondaryText.opacity(0.14).gradient)
        }
    }
    
    private var headerForeground: Color {
        switch accent {
        case .blue:
            // Use black text in light mode, white text in dark mode
            return colorScheme == .dark ? .white : .black
        case .purple:
            return .brandBlue
        case .teal:
            return colorScheme == .dark ? .white : .black
        case .goldenYellow:
            return colorScheme == .dark ? Color(hex: "4A90E2") : .brandBlue
        case .dimmedGreen:
            return .leafGreen.opacity(0.6)
        case .gray:
            return .dynamicSecondaryText
        }
    }
    
    private var cardBackground: some ShapeStyle {
        Color.dynamicCardBackground
    }
    
    private var borderColor: some ShapeStyle {
        switch accent {
        case .blue:
            return Color.brandBlue.opacity(0.25)
        case .purple:
            return Color.brandBlue.opacity(0.20)
        case .teal:
            return Color.leafGreen.opacity(0.25)
        case .goldenYellow:
            return Color.leafYellow.opacity(0.25)
        case .dimmedGreen:
            return Color.leafGreen.opacity(0.15)
        case .gray:
            return Color.dynamicSecondaryText.opacity(0.22)
        }
    }
}

// MARK: - Supporting Types

enum SectionAccent: CaseIterable {
    case blue, purple, teal, gray, goldenYellow, dimmedGreen
}

#Preview {
    VStack(spacing: 20) {
        // Active section (blue)
        SectionCard(
            title: "Morning Focus",
            icon: "sun.max.fill",
            accent: .blue,
            collapsed: .constant(false),
            dimmed: false
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Step 1 – My Why").font(.subheadline).bold()
                TextEditor(text: .constant("Sample why text"))
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        
        // Past section (purple, dimmed)
        SectionCard(
            title: "Last Night's Prep (for Today)",
            icon: "moon.stars.fill",
            accent: .purple,
            collapsed: .constant(true),
            dimmed: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample prep items would appear here")
                    .foregroundStyle(.secondary)
            }
        }
        
        // Teal section
        SectionCard(
            title: "End of Day",
            icon: "sunset.fill",
            accent: .teal,
            collapsed: .constant(false)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sample end of day content")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Morning Focus Specific Card (No Collapse)
struct MorningFocusCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    let isCompleted: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        icon: String,
        isCompleted: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isCompleted = isCompleted
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (no chevron, no collapse)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                // Show checkmark when completed
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .accessibilityLabel("Completed")
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.morningFocusBackground)
            )
            .clipShape(.rect(cornerRadius: 16, style: .continuous))

            // Content (always visible)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.morningFocusBackground)
        ) // Single background for entire card
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }
}
