import SwiftUI

struct MilestoneCelebrationOverlay: View {
    @Binding var isPresented: Bool
    let streakCount: Int
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var confettiOpacity: Double = 0.0
    
    var body: some View {
        if isPresented {
            GeometryReader { geometry in
                ZStack {
                    // Full-screen dim background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissCelebration()
                        }
                    
                    // Confetti background
                    ConfettiView()
                        .opacity(confettiOpacity)
                        .allowsHitTesting(false)
                    
                    // Milestone celebration card
                    VStack(spacing: 20) {
                        // Streak badge
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.6)],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(Color.yellow, lineWidth: 3)
                                )
                            
                            VStack(spacing: 4) {
                                Text("\(streakCount)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("DAYS")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .scaleEffect(cardScale)
                        
                        // Milestone message
                        VStack(spacing: 12) {
                            VStack(spacing: 8) {
                            Text("Milestone Achieved!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    .multilineTextAlignment(.center)
                                
                                Text("🎉  🎉  🎉")
                                    .font(.title3)
                            }
                            
                            Text(message)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        .opacity(textOpacity)
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    )
                    .frame(maxWidth: 320)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }
            .onAppear {
                startCelebration()
            }
        }
    }
    
    private func startCelebration() {
        // Card entrance animation
        withAnimation(.easeOut(duration: 0.6)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
        
        // Confetti appears
        withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
            confettiOpacity = 1.0
        }
        
        // Text fades in
        withAnimation(.easeIn(duration: 0.8).delay(0.6)) {
            textOpacity = 1.0
        }
        
        // Auto-dismiss after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            dismissCelebration()
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeIn(duration: 0.3)) {
            cardScale = 0.8
            cardOpacity = 0.0
            textOpacity = 0.0
            confettiOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    MilestoneCelebrationOverlay(
        isPresented: .constant(true),
        streakCount: 7,
        message: "One week strong — your future self is cheering! 🎉"
    )
}
