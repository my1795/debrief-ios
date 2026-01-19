//
//  RecordingPulseView.swift
//  debrief
//
//  Animated pulsing microphone icon for recording state
//

import SwiftUI

struct RecordingPulseView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPulsing ? 1.5 + CGFloat(index) * 0.2 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.3),
                        value: isPulsing
                    )
            }
            
            // Middle glow ring
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 140, height: 140)
                .scaleEffect(isPulsing ? 1.1 : 0.95)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            // Main circle with microphone
            Circle()
                .fill(Color.red)
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.05 : 0.98)
                .shadow(color: .red.opacity(0.5), radius: 20)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .scaleEffect(isPulsing ? 1.0 : 0.95)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                )
        }
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "134E4A")
            .ignoresSafeArea()
        
        VStack {
            RecordingPulseView()
            
            Text("Recording...")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 32)
        }
    }
}
