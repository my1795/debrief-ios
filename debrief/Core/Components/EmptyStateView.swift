//
//  EmptyStateView.swift
//  debrief
//
//  Created for Phase 3 UI Consolidation
//

import SwiftUI

/// Reusable empty state component for consistent empty/error states across the app.
struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text(title)
                .font(.title2)
                .bold()
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.primaryButton)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Empty state for no debriefs
    static func noDebriefs(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "No Debriefs Yet",
            message: "Record your first debrief after a call.",
            action: action,
            actionTitle: action != nil ? "Record Now" : nil
        )
    }
    
    /// Empty state for no contacts
    static func noContacts() -> EmptyStateView {
        EmptyStateView(
            icon: "person.2.slash",
            title: "No Contacts",
            message: "No contacts found."
        )
    }
    
    /// Empty state for permission denied
    static func permissionDenied(message: String) -> EmptyStateView {
        EmptyStateView(
            icon: "lock.fill",
            title: "Access Needed",
            message: message
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.Gradients.mainBackground.ignoresSafeArea()
        
        VStack(spacing: 40) {
            EmptyStateView.noDebriefs()
            
            Divider().background(.white.opacity(0.2))
            
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "Try adjusting your search or filters."
            )
        }
    }
}
