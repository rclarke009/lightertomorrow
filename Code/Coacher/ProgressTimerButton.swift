//
//  ProgressTimerButton.swift
//  Coacher
//
//  Created by Rebecca Clarke on 8/30/25.
//

import SwiftUI

struct ProgressTimerButton: View {
    let title: String
    let duration: TimeInterval
    let onComplete: () -> Void
    
    @State private var progress: Double = 0
    @State private var isTimerActive = false
    @State private var timer: Timer?
    
    private let timerInterval: TimeInterval = 0.1
    
    var body: some View {
        Button(action: {
            if !isTimerActive {
                startTimer()
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTimerActive ? Color.gray.opacity(0.3) : Color.blue)
                    .frame(height: 50)
                
                // Progress bar
                if isTimerActive {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                            .frame(width: progress * 280) // Approximate width based on button
                            .animation(.linear(duration: timerInterval), value: progress)
                        Spacer()
                    }
                }
                
                // Text
                Text(isTimerActive ? "Feeling it..." : title)
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.medium)
            }
        }
        .disabled(isTimerActive)
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        isTimerActive = true
        progress = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            progress += timerInterval / duration
            
            if progress >= 1.0 {
                stopTimer()
                onComplete()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
        progress = 0
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressTimerButton(
            title: "Feel it for 10 seconds",
            duration: 10.0
        ) {
            print("Timer completed!")
        }
        
        ProgressTimerButton(
            title: "Feel it for 5 seconds",
            duration: 5.0
        ) {
            print("Timer completed!")
        }
    }
    .padding()
}
