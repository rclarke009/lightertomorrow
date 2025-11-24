//
//  SparkleProgressView.swift
//  Coacher
//
//  Created by Rebecca Clarke on 9/6/25.
//

import SwiftUI

struct SparkleProgressView: View {
    @State private var progress: Double = 0.0
    @State private var sparkles: [Sparkle] = []
    @State private var animationTimer: Timer?
    
    let isLoading: Bool
    let progressValue: Double
    
    init(isLoading: Bool, progressValue: Double = 0.0) {
        self.isLoading = isLoading
        self.progressValue = progressValue
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress bar with sparkles
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                
                // Progress fill
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.brandBlue, .helpButtonBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, progress * 200))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    Spacer(minLength: 0)
                }
                
                // Sparkles overlay
                ForEach(sparkles) { sparkle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: sparkle.size, height: sparkle.size)
                        .position(x: sparkle.x, y: sparkle.y)
                        .opacity(sparkle.opacity)
                        .scaleEffect(sparkle.scale)
                        .animation(.easeInOut(duration: sparkle.duration), value: sparkle.opacity)
                }
            }
            .frame(width: 200)
            .clipped()
            
            // Loading text
            Text("Preparing your AI coach...")
                .font(.headline)
                .foregroundColor(.helpButtonBlue)
            
            Text("This may take a few minutes on first launch")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            if isLoading {
                startProgressAnimation()
                startSparkleAnimation()
            }
        }
        .onDisappear {
            stopAnimations()
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                startProgressAnimation()
                startSparkleAnimation()
            } else {
                // Model finished loading - show completion
                completeProgress()
            }
        }
        .onChange(of: progressValue) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                progress = newValue
            }
        }
    }
    
    private func startProgressAnimation() {
        // Simulate progress if no real progress value provided
        if progressValue == 0.0 {
            // Reset progress to 0 when starting
            progress = 0.0
            
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if self.isLoading && self.progress < 0.85 {
                    // Much slower, more realistic progress pattern:
                    // - Very slow progress that should take 2-3 minutes to reach 85%
                    // - This way it won't finish before the actual model loads
                    let increment: Double
                    if self.progress < 0.2 {
                        increment = 0.001  // Very slow start
                    } else if self.progress < 0.6 {
                        increment = 0.0008  // Even slower middle
                    } else {
                        increment = 0.0005  // Very slow finish
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.progress += increment
                    }
                }
            }
        } else {
            progress = progressValue
        }
    }
    
    private func startSparkleAnimation() {
        // Create sparkles periodically
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if self.isLoading {
                self.addSparkle()
            }
        }
    }
    
    private func addSparkle() {
        let sparkle = Sparkle(
            x: CGFloat.random(in: 20...180),
            y: CGFloat.random(in: 4...12),
            size: CGFloat.random(in: 2...6),
            opacity: 0.0,
            scale: 0.5,
            duration: Double.random(in: 0.8...1.5)
        )
        
        sparkles.append(sparkle)
        
        // Animate sparkle appearance
        withAnimation(.easeOut(duration: 0.3)) {
            if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                sparkles[index].opacity = 1.0
                sparkles[index].scale = 1.0
            }
        }
        
        // Remove sparkle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + sparkle.duration) {
            withAnimation(.easeIn(duration: 0.3)) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
    
    private func completeProgress() {
        // Stop the timer first
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Animate to 100% completion
        withAnimation(.easeInOut(duration: 1.0)) {
            progress = 1.0
        }
        
        // Clear sparkles after completion animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                sparkles.removeAll()
            }
        }
    }
    
    private func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
        sparkles.removeAll()
    }
}

struct Sparkle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var scale: CGFloat
    var duration: Double
}

#Preview {
    VStack(spacing: 40) {
        SparkleProgressView(isLoading: true)
        SparkleProgressView(isLoading: false)
    }
    .padding()
}
