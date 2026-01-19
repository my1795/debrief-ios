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

// MARK: - Helper
private func formatStat(_ value: String) -> String {
    if let intVal = Int(value), intVal > 99 {
        return "99+"
    }
    return value
}

/// Groups multiple stat items into a single pill
struct GroupedStatsPillView: View {
    let leftItems: [(icon: String, value: String)]
    let rightItems: [(icon: String, value: String, label: String?)]
    
    // Info Sheet Data
    var infoTitle: String? = nil
    var infoDetails: [(icon: String, text: String)]? = nil
    
    @State private var showInfo = false
    
    var body: some View {
        HStack(spacing: 8) { // Increased spacing between groups
            // Left group (e.g., debriefs/calls)
            HStack(spacing: 4) {
                ForEach(Array(leftItems.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Text("/")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .font(.caption2) // Smaller separator
                    }
                    Image(systemName: item.icon) // SF Symbol
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(formatStat(item.value)) // Cap at 99+
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .fixedSize() // Prevent text wrapping
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12)) // Softer corners
            
            // Right items (each in own pill)
            ForEach(Array(rightItems.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Image(systemName: item.icon) // SF Symbol
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(item.value) // Duration usually doesn't need 99+ cap in same way (m/s)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .fixedSize()
                    if let label = item.label {
                        Text(label)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let details = infoDetails {
                Button(action: { showInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .sheet(isPresented: $showInfo) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let title = infoTitle {
                            Text(title)
                                .font(.headline)
                                .padding(.top, 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                                HStack(spacing: 12) {
                                    Image(systemName: detail.icon)
                                        .font(.title3)
                                        .frame(width: 24, alignment: .center)
                                        .foregroundStyle(AppTheme.Colors.accent) // Brand color
                                    
                                    Text(detail.text)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { showInfo = false }) {
                            Text("Got it")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 24)
                    .applySheetPresentationStyle()
                    .background(AppTheme.Colors.darkBackground) // Match app theme
                }
            }
        }
    }
}

// MARK: - Compatibility Extension
private extension View {
    @ViewBuilder
    func applySheetPresentationStyle() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        } else if #available(iOS 16.0, *) {
            self
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
        } else {
            self
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
