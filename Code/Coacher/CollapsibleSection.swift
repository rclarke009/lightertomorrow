//
//  CollapsibleSection.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct CollapsibleSection<Header: View, Content: View>: View {
    let title: String
    let isExpanded: Bool
    let isDimmed: Bool
    let headerContent: Header
    let content: Content
    let onToggle: () -> Void
    
    init(
        title: String,
        isExpanded: Bool,
        isDimmed: Bool = false,
        @ViewBuilder headerContent: () -> Header,
        @ViewBuilder content: () -> Content,
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.isDimmed = isDimmed
        self.headerContent = headerContent()
        self.content = content()
        self.onToggle = onToggle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with disclosure triangle
            Button(action: onToggle) {
                HStack {
                    headerContent
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(isDimmed ? .secondary : .primary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                )
            }
            .buttonStyle(.plain)
            
            // Content (collapsible)
            if isExpanded {
                content
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .opacity(isDimmed ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private var backgroundColor: Color {
        if isDimmed {
            return Color(.systemPurple).opacity(0.1)
        } else {
            return Color(.systemBlue).opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CollapsibleSection(
            title: "Active Section",
            isExpanded: true,
            isDimmed: false
        ) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.blue)
                Text("Morning Focus")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        } content: {
            Text("This is the expanded content for the active section.")
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        } onToggle: {
            // Toggle logic
        }
        
        CollapsibleSection(
            title: "Past Section",
            isExpanded: false,
            isDimmed: true
        ) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.purple)
                Text("Last Night's Prep")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        } content: {
            Text("This is the collapsed content for the past section.")
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        } onToggle: {
            // Toggle logic
        }
    }
    .padding()
}
