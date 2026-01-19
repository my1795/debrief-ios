//
//  AnimatedWaveformView.swift
//  debrief
//
//  Animated waveform visualization for audio player
//

import SwiftUI

struct AnimatedWaveformView: View {
    let isPlaying: Bool
    let isLoading: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    // Fixed bar heights for consistent look
    private let barHeights: [CGFloat] = [
        0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 0.5, 0.7, 0.4,
        0.6, 0.9, 0.5, 0.7, 0.8, 0.4, 0.6, 0.9, 0.5, 0.7,
        0.8, 0.6, 0.4, 0.7, 0.5
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<barHeights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(height: barHeight(for: index, in: geometry.size.height))
                        .animation(
                            isPlaying ? .easeInOut(duration: 0.3).delay(Double(index) * 0.02) : .easeOut(duration: 0.2),
                            value: isPlaying
                        )
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            if isPlaying {
                startAnimation()
            }
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private var barColor: Color {
        if isLoading {
            return Color(hex: "5EEAD4").opacity(0.3)
        } else if isPlaying {
            return Color(hex: "5EEAD4").opacity(0.8)
        } else {
            return Color(hex: "5EEAD4").opacity(0.3)
        }
    }
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        let baseHeight = barHeights[index] * maxHeight
        
        if isLoading {
            // Subtle pulse animation when loading
            let pulse = sin(animationPhase + CGFloat(index) * 0.3) * 0.2 + 0.8
            return baseHeight * pulse * 0.5
        } else if isPlaying {
            // Active waveform animation
            let wave = sin(animationPhase + CGFloat(index) * 0.5) * 0.3 + 0.7
            return baseHeight * wave
        } else {
            // Static minimal bars
            return baseHeight * 0.4
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Idle")
        AnimatedWaveformView(isPlaying: false, isLoading: false)
            .frame(height: 32)
            .background(Color.black.opacity(0.3))
        
        Text("Loading")
        AnimatedWaveformView(isPlaying: false, isLoading: true)
            .frame(height: 32)
            .background(Color.black.opacity(0.3))
        
        Text("Playing")
        AnimatedWaveformView(isPlaying: true, isLoading: false)
            .frame(height: 32)
            .background(Color.black.opacity(0.3))
    }
    .padding()
    .background(Color(hex: "134E4A"))
}
