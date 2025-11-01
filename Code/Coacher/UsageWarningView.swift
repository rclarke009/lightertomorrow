//
//  UsageWarningView.swift
//  Coacher
//
//  Friendly warning view shown when user reaches 80% of monthly token usage
//

import SwiftUI

struct UsageWarningView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var usageTracker = UsageTracker.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // Title
            Text("Usage Update")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Current Usage
            VStack(spacing: 12) {
                Text("You've used \(formatNumber(usageTracker.currentUsage)) of \(formatNumber(100_000)) tokens this month")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(usageTracker.usagePercentage), height: 12)
                    }
                }
                .frame(height: 12)
                
                Text("\(Int(usageTracker.usagePercentage * 100))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Renewal Info
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Your usage resets on \(usageTracker.getRenewalDateString())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            .padding(.horizontal)
            
            // Encouragement
            Text("You're doing great! Your limit will reset soon.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action Button
            Button("Got it") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 8)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
        .padding(.horizontal, 20)
        .onAppear {
            // Refresh usage data when view appears
            _ = usageTracker.getCurrentUsage()
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    UsageWarningView()
        .background(Color.gray.opacity(0.3))
}
