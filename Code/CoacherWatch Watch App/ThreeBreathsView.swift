//
//  ThreeBreathsView.swift
//  Coacher Watch
//
//  Created on 9/6/25.
//

import SwiftUI
import WatchKit

struct ThreeBreathsView: View {
    @State private var scale: CGFloat = 0.8
    @State private var breathCount = 0
    @State private var isInhaling = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Breath \(breathCount + 1) of 3")
                .font(.system(size: 16, weight: .semibold))
            
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(Color.blue, lineWidth: 8)
                    .frame(width: 90, height: 90)
                    .scaleEffect(scale)
            }
            
            Text(isInhaling ? "Inhale" : "Exhale")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
        }
        .onAppear {
            startBreathingCycle()
        }
    }
    
    private func startBreathingCycle() {
        // 4s inhale, 6s exhale = 10s per breath x 3 = 30s total
        animateBreath()
    }
    
    private func animateBreath() {
        // Inhale (expand)
        isInhaling = true
        WKInterfaceDevice.current().play(.start)
        
        withAnimation(.easeInOut(duration: 4)) {
            scale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            // Exhale (contract)
            self.isInhaling = false
            WKInterfaceDevice.current().play(.stop)
            
            withAnimation(.easeInOut(duration: 6)) {
                self.scale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.breathCount += 1
                
                if self.breathCount < 3 {
                    self.animateBreath()
                } else {
                    self.completeBreathing()
                }
            }
        }
    }
    
    private func completeBreathing() {
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ThreeBreathsView()
    }
}
