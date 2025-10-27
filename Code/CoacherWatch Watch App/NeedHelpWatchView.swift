//
//  NeedHelpWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import WatchConnectivity

struct NeedHelpWatchView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Encouragement message
            Text(randomEncouragement)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            
            // Urge Timer button
            NavigationLink(destination: UrgeTimerView()) {
                HStack {
                    Image(systemName: "timer")
                    Text("Urge Timer")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
        .navigationTitle("Need Help")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private let encouragements = [
        "You've got this! 💪",
        "Take a deep breath 🌬️",
        "You're stronger than you feel ✨",
        "One moment at a time 🕐",
        "This feeling will pass 🌙",
        "You're not alone 🤗",
        "You can do hard things 💫",
        "Progress, not perfection 🌱"
    ]
    
    private var randomEncouragement: String {
        encouragements.randomElement() ?? encouragements[0]
    }
}

#Preview {
    NavigationStack {
        NeedHelpWatchView()
    }
}
