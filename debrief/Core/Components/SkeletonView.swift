//
//  SkeletonView.swift
//  debrief
//
//  Created for Phase 5 UX Polish
//

import SwiftUI

/// A shimmer loading skeleton view for placeholder content.
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preset Skeleton Layouts

/// Skeleton for a debrief list item
struct DebriefSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            SkeletonView(width: 44, height: 44, cornerRadius: 22)
            
            VStack(alignment: .leading, spacing: 8) {
                // Name
                SkeletonView(width: 120, height: 14)
                // Summary
                SkeletonView(height: 12)
            }
            
            Spacer()
            
            // Time
            SkeletonView(width: 40, height: 12)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Skeleton for stats cards
struct StatsSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    SkeletonView(width: 24, height: 24, cornerRadius: 12)
                    SkeletonView(width: 40, height: 20)
                    SkeletonView(width: 60, height: 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.Colors.darkBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            StatsSkeletonView()
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                DebriefSkeletonView()
                DebriefSkeletonView()
                DebriefSkeletonView()
            }
            .padding(.horizontal)
        }
    }
}
