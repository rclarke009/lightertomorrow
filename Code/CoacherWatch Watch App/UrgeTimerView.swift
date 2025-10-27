//
//  UrgeTimerView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import SwiftData
import WatchKit

struct UrgeTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMinutes = 5
    @State private var timeRemaining: TimeInterval = 0
    @State private var isTimerRunning = false
    @State private var showCompletion = false
    @Environment(\.dismiss) var dismiss
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if showCompletion {
                    // Completion view
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("You did it! 🎉")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Urge rode out successfully")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .onAppear {
                        WKInterfaceDevice.current().play(.notification)
                        logUrgeRideOut()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            dismiss()
                        }
                    }
                } else if isTimerRunning {
                    // Timer running view
                    TimerRunningView(timeRemaining: timeRemaining)
                } else {
                    // Time picker
                    VStack(spacing: 24) {
                        Text("Set timer duration")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(1...30, id: \.self) { minute in
                                Text("\(minute) min")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        
                        Button("Start Timer") {
                            startTimer()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(false)
        .navigationBarTitleDisplayMode(.automatic)
        .onReceive(timer) { _ in
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
                
                // Haptic feedback every minute
                if Int(timeRemaining) % 60 == 0 && timeRemaining > 0 {
                    WKInterfaceDevice.current().play(.start)
                }
                
                if timeRemaining <= 0 {
                    completeTimer()
                }
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = TimeInterval(selectedMinutes * 60)
        isTimerRunning = true
    }
    
    private func completeTimer() {
        isTimerRunning = false
        WKInterfaceDevice.current().play(.notification)
        
        withAnimation {
            showCompletion = true
        }
    }
    
    private func endTimer() {
        isTimerRunning = false
        dismiss()
    }
    
    private func logUrgeRideOut() {
        let craving = CravingNote(
            type: .other,
            text: "Rode out urge for \(selectedMinutes) minutes",
            keptAudio: false
        )
        
        modelContext.insert(craving)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save craving note: \(error)")
        }
    }
}

struct TimerRunningView: View {
    let timeRemaining: TimeInterval
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            Text(formatTime(timeRemaining))
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            // Breathing ring animation
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(Color.blue, lineWidth: 6)
                    .frame(width: 70, height: 70)
                    .scaleEffect(scale)
            }
            .onAppear {
                // Slow breathing: 6 second inhale, 8 second exhale for calm breathing
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    scale = 1.25
                }
            }
            
            Text("Breathe")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        UrgeTimerView()
    }
}
