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
    @State private var showLocalAIConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    // Blue Sparkle Icon
                    Image(systemName: hybridManager.isUsingCloudAI ? "sparkles" : "sparkles")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(hybridManager.isUsingCloudAI ? .secondary : (colorScheme == .dark ? .white : .brandBlue))
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text(hybridManager.isUsingCloudAI ? "Switch to Local AI" : "Upgrade to Online AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(hybridManager.isUsingCloudAI ? 
                         "Switch back to your local AI model for complete privacy" :
                         "Get access to the most advanced AI model for enhanced coaching")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    if hybridManager.isUsingCloudAI {
                        // Local AI features
                        FeatureRow(
                            icon: "lock.fill",
                            title: "Complete Privacy",
                            description: "All data stays on your device",
                            iconColor: colorScheme == .dark ? .white : .brandBlue
                        )
                        
                        FeatureRow(
                            icon: "wifi.slash",
                            title: "No Internet Required",
                            description: "Works offline anytime",
                            iconColor: colorScheme == .dark ? .white : .brandBlue
                        )
                        
                        FeatureRow(
                            icon: "battery.100",
                            title: "Battery Efficient",
                            description: "Optimized for mobile devices",
                            iconColor: colorScheme == .dark ? .white : .brandBlue
                        )
                        
                        FeatureRow(
                            icon: "checkmark.shield",
                            title: "Always Available",
                            description: "No server dependencies",
                            iconColor: colorScheme == .dark ? .white : .brandBlue
                        )
                    } else {
                        // Online AI features
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
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Privacy Notice
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(hybridManager.isUsingCloudAI ? .green : (colorScheme == .dark ? .white : .blue))
                        Text(hybridManager.isUsingCloudAI ? "Privacy Benefits" : "Privacy Notice")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    Text(hybridManager.isUsingCloudAI ? 
                         "Your local AI keeps all conversations completely private on your device. No data is ever sent to external servers." :
                         "When using online AI, your messages are sent to secure servers for processing. Your conversation history remains private and is not used for training.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background((hybridManager.isUsingCloudAI ? Color.green : Color.blue).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer(minLength: 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: hybridManager.isUsingCloudAI ? switchToLocalAI : enableOnlineAI) {
                        HStack {
                            if isEnabling {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: hybridManager.isUsingCloudAI ? "sparkles" : "sparkles")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(isEnabling ? 
                                 (hybridManager.isUsingCloudAI ? "Switching..." : "Enabling...") :
                                 (hybridManager.isUsingCloudAI ? "Switch to Local AI" : "Enable Online AI"))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hybridManager.isUsingCloudAI ? Color.green : Color.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isEnabling)
                    
                    Button(hybridManager.isUsingCloudAI ? "Keep Using Online AI" : "Keep Using Local AI") {
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
    
    private func switchToLocalAI() {
        isEnabling = true
        
        Task {
            await hybridManager.switchToLocalAI()
            
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
