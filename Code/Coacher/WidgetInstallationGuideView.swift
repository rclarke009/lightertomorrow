//
//  WidgetInstallationGuideView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 10/26/25.
//

import SwiftUI

struct WidgetInstallationGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Add Lighter to Your Home Screen")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Get quick access to your morning plan and helpful tools right from your home screen!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What You'll Get:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            BenefitRow(icon: "sun.max.fill", title: "Morning Plan", description: "See your daily focus at a glance")
                            BenefitRow(icon: "hand.raised.fill", title: "Quick Help", description: "Access 'I Need Help' instantly")
                            BenefitRow(icon: "star.fill", title: "Celebrate Wins", description: "Capture successes immediately")
                            BenefitRow(icon: "leaf.fill", title: "Stay Connected", description: "Tap to open the full app")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Installation Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Add:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            StepRow(number: 1, text: "Long press on your home screen")
                            StepRow(number: 2, text: "Tap 'Edit' in the top left")
                            StepRow(number: 3, text: "Search for 'Lighter' or scroll to find it")
                            StepRow(number: 4, text: "Choose your preferred widget size")
                            StepRow(number: 5, text: "Tap 'Add Widget'")
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Widget Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                       ToolbarItem(placement: .navigationBarTrailing) {
                           Button("Done") {
                               dismiss()
                           }
                           .accessibilityLabel("Done")
                           .accessibilityHint("Closes widget installation guide")
                       }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(description)")
            
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
                   Text(text)
                       .font(.subheadline)
                       .accessibilityLabel("Step \(number): \(text)")
            
            Spacer()
        }
    }
}

#Preview {
    WidgetInstallationGuideView()
}
