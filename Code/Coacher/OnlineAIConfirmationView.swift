//
//  OnlineAIConfirmationView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 9/6/25.
//

import SwiftUI

struct OnlineAIConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var hybridManager: HybridLLMManager
    @State private var isEnabling = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    // Blue Sparkle Icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .brandBlue)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text("Enhanced Online AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("Experience richer, more contextual coaching powered by our cloud-based AI.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Advanced AI Model",
                        description: "More intelligent and contextual responses",
                        iconColor: colorScheme == .dark ? .white : .brandBlue
                    )
                    
                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Faster Responses",
                        description: "Quick and efficient conversation flow",
                        iconColor: colorScheme == .dark ? .white : .brandBlue
                    )
                    
                    FeatureRow(
                        icon: "globe",
                        title: "Always Updated",
                        description: "Latest AI capabilities and improvements",
                        iconColor: colorScheme == .dark ? .white : .brandBlue
                    )
                    
                    FeatureRow(
                        icon: "lock.fill",
                        title: "Secure & Private",
                        description: "Your data is encrypted and protected",
                        iconColor: colorScheme == .dark ? .white : .brandBlue
                    )
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Privacy Notice
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(colorScheme == .dark ? .white : .blue)
                        Text("Privacy Notice")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    Text("When using online AI, your messages are sent to secure servers for processing. Your conversation history remains private and is not used for training.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: enableOnlineAI) {
                        HStack {
                            if isEnabling {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(isEnabling ? "Enabling..." : "Enable Online AI")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isEnabling)
                    
                    Button("Not Now") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
            }
        }
    }
    
    private func enableOnlineAI() {
        isEnabling = true
        
        Task {
            await hybridManager.switchToCloudAI()
            
            await MainActor.run {
                isEnabling = false
                dismiss()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnlineAIConfirmationView()
        .environmentObject(HybridLLMManager())
}
