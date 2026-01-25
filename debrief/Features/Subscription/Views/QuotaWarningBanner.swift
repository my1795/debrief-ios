//
//  QuotaWarningBanner.swift
//  debrief
//
//  Optional warning banner - currently unused in favor of inline quota section upgrade prompt
//  Keeping for potential future use in other screens
//

import SwiftUI

/// Compact upgrade prompt for inline use (e.g., in quota sections)
/// This is the preferred approach - subtle, not distracting
struct InlineUpgradePrompt: View {
    @ObservedObject var subscriptionState = SubscriptionState.shared
    var onUpgradeTap: () -> Void

    var body: some View {
        if subscriptionState.currentTier == .free && subscriptionState.highestUsagePercent >= 80 {
            Button(action: onUpgradeTap) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.subheadline)
                    Text("Upgrade for unlimited")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "022c22").ignoresSafeArea()

        VStack(spacing: 20) {
            InlineUpgradePrompt(onUpgradeTap: {})
                .padding(.horizontal)
        }
    }
}
