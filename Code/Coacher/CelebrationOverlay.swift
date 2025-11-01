import SwiftUI

struct CelebrationOverlay: View {
    @Binding var isPresented: Bool
    let title: String
    let subtitle: String
    
    @EnvironmentObject private var celebrationManager: CelebrationManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var plantScale: CGFloat = 0.1
    
    // Reset animation state when overlay appears
    private func resetAnimationState() {
        cardScale = 0.8
        cardOpacity = 0.0
        textOpacity = 0.0
        plantScale = 0.1
    }
    
    var body: some View {
        if isPresented {
            GeometryReader { geometry in
                ZStack {
                    // Transparent background - no overlay
                    Color.clear
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissCelebration()
                        }
                    
                    // Centered celebration card
                    VStack(spacing: 20) {
                        // Apple icon
                        if celebrationManager.animationsEnabled {
                            // Animated Apple with bite
                            ZStack {
                                // Main apple body
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red.opacity(0.8), lineWidth: 2)
                                    )
                                
                                // Bite taken out (using a smaller circle overlay)
                                Circle()
                                    .fill(Color(red: 0.99, green: 0.97, blue: 0.94))
                                    .frame(width: 25, height: 25)
                                    .offset(x: 15, y: -15)
                                
                                // Apple stem
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.brown)
                                    .frame(width: 4, height: 8)
                                    .offset(x: 0, y: -34)
                            }
                            .scaleEffect(plantScale)
                            .animation(
                                .easeInOut(duration: 1.5)
                                    .repeatCount(1, autoreverses: false),
                                value: plantScale
                            )
                        } else {
                            // Static Apple with bite (no animations)
                            ZStack {
                                // Main apple body
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red.opacity(0.8), lineWidth: 2)
                                    )
                                
                                // Bite taken out (using a smaller circle overlay)
                                Circle()
                                    .fill(Color(red: 0.99, green: 0.97, blue: 0.94))
                                    .frame(width: 25, height: 25)
                                    .offset(x: 15, y: -15)
                                
                                // Apple stem
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.brown)
                                    .frame(width: 4, height: 8)
                                    .offset(x: 0, y: -34)
                            }
                            .scaleEffect(1.0) // Always full size when static
                        }
                        
                        // Celebration message
                        Text(subtitle)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            .multilineTextAlignment(.center)
                            .opacity(textOpacity)
                            .scaleEffect(textOpacity)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }
            .onAppear {
                resetAnimationState()
                startCelebration()
            }
        }
    }
    
    private func startCelebration() {
        // Card entrance animation
        withAnimation(.easeOut(duration: 0.4)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
        
        if celebrationManager.animationsEnabled {
            // Plant growth animation
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                plantScale = 1.0
            }
        } else {
            // No animations - keep plant small
            plantScale = 0.3
        }
        
        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            textOpacity = 1.0
        }
        
        // Auto-dismiss after animation
        let dismissDelay = celebrationManager.animationsEnabled ? 4.5 : 2.5
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            dismissCelebration()
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeIn(duration: 0.3)) {
            cardScale = 0.8
            cardOpacity = 0.0
            textOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    CelebrationOverlay(
        isPresented: .constant(true),
        title: "Swap logged!",
        subtitle: "Small steps, big wins."
    )
}
