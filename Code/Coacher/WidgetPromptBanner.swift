//
//  WidgetPromptBanner.swift
//  Coacher
//
//  Created by Rebecca Clarke on 10/26/25.
//

import SwiftUI

struct WidgetPromptBanner: View {
    let onShowGuide: () -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Add widget for quick access!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Get your morning plan on your home screen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Show Me How") {
                onShowGuide()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        WidgetPromptBanner(
            onShowGuide: {},
            onDismiss: {}
        )
        Spacer()
    }
}
