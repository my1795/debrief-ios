//
//  StatsPillView.swift
//  debrief
//
//  Created for Phase 3 UI Consolidation
//

import SwiftUI

/// A single stat item displayed in pill format
struct StatPillItem: Identifiable {
    let id = UUID()
    let emoji: String
    let value: String
    var label: String? = nil
}

/// Reusable stats pill component for displaying compact stat groups.
struct StatsPillView: View {
    let items: [StatPillItem]
    var spacing: CGFloat = 6
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(items) { item in
                HStack(spacing: 4) {
                    Text(item.emoji)
                    
                    Text(item.value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    if let label = item.label {
                        Text(label)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Convenience Factory

extension StatsPillView {
    /// Creates daily stats pills (debriefs/calls + duration)
    static func dailyStats(debriefs: Int, calls: Int, minutes: Int) -> StatsPillView {
        StatsPillView(items: [
            StatPillItem(emoji: "📝", value: "\(debriefs)/", label: nil),
            StatPillItem(emoji: "📞", value: "\(calls)", label: nil),
            StatPillItem(emoji: "⏱️", value: "\(minutes)", label: "min")
        ])
    }
}

// MARK: - Grouped Variant

/// Groups multiple stat items into a single pill
struct GroupedStatsPillView: View {
    let leftItems: [(emoji: String, value: String)]
    let rightItems: [(emoji: String, value: String, label: String?)]
    
    var body: some View {
        HStack(spacing: 6) {
            // Left group (e.g., debriefs/calls)
            HStack(spacing: 4) {
                ForEach(Array(leftItems.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Text("/")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Text(item.emoji)
                    Text(item.value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Right items (each in own pill)
            ForEach(Array(rightItems.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Text(item.emoji)
                    Text(item.value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    if let label = item.label {
                        Text(label)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.Colors.darkBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Simple pills
            StatsPillView(items: [
                StatPillItem(emoji: "📝", value: "5"),
                StatPillItem(emoji: "⏱️", value: "12", label: "min")
            ])
            
            // Grouped variant
            GroupedStatsPillView(
                leftItems: [("📝", "3"), ("📞", "5")],
                rightItems: [("⏱️", "8", "min")]
            )
        }
    }
}
