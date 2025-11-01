import SwiftUI

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .teal]
    
    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            createConfetti()
            startAnimation()
        }
    }
    
    private func createConfetti() {
        confetti = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: Double.random(in: 0...1),
                y: Double.random(in: -0.2...0),
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.5...1.5),
                color: colors.randomElement() ?? .blue,
                delay: Double.random(in: 0...0.5)
            )
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        
        withAnimation(.easeOut(duration: 3.0).delay(0.1)) {
            for i in confetti.indices {
                confetti[i].y = Double.random(in: 0.8...1.2)
                confetti[i].rotation += Double.random(in: 180...720)
                confetti[i].x += Double.random(in: -0.3...0.3)
            }
        }
        
        // Auto-hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                isAnimating = false
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: Double
    var y: Double
    var rotation: Double
    var scale: Double
    let color: Color
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) * 0.02 * piece.scale
            
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color)
                .frame(width: size, height: size * 2)
                .position(
                    x: piece.x * geometry.size.width,
                    y: piece.y * geometry.size.height
                )
                .rotationEffect(.degrees(piece.rotation))
                .opacity(piece.delay > 0 ? 0 : 1)
                .animation(
                    .easeOut(duration: 3.0)
                        .delay(piece.delay),
                    value: piece.y
                )
        }
    }
}

#Preview {
    ConfettiView()
        .frame(width: 300, height: 400)
        .background(Color.black.opacity(0.1))
}
