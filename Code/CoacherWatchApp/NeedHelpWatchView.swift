//
//  NeedHelpWatchView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI

struct NeedHelpWatchView: View {
    @State private var showEncouragement = false
    @Environment(\.dismiss) var dismiss
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            if showEncouragement {
                Text(randomEncouragement)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 8) {
                    Button(action: {
                        // Navigate to urge timer
                    }) {
                        HStack {
                            Image(systemName: "timer")
                            Text("Start Urge Timer")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Open on iPhone
                        openOniPhone()
                    }) {
                        HStack {
                            Image(systemName: "iphone")
                            Text("Open on iPhone")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
            } else {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                    .onTapGesture {
                        withAnimation {
                            showEncouragement = true
                        }
                    }
                
                Text("Tap the leaf")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Need Help")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var randomEncouragement: String {
        encouragements.randomElement() ?? encouragements[0]
    }
    
    private func openOniPhone() {
        // Use WatchConnectivity to open iPhone app
        // This will be implemented with WCSession
    }
}

#Preview {
    NavigationStack {
        NeedHelpWatchView()
    }
}

