//
//  ErrorBannerView.swift
//  debrief
//
//  Created for Production Refactoring
//

import SwiftUI

/// Reusable error banner with optional retry action.
/// Displays user-friendly message from AppError.
struct ErrorBannerView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: error.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            // Message
            VStack(alignment: .leading, spacing: 2) {
                Text(errorTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text(error.userMessage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                if error.isRetryable, let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    private var errorTitle: String {
        switch error {
        case .network: return "Connection Error"
        case .unauthorized: return "Session Expired"
        case .notFound: return "Not Found"
        case .serverError: return "Server Error"
        case .unknown: return "Error"
        }
    }
    
    private var backgroundColor: Color {
        switch error {
        case .network:
            return Color.orange.opacity(0.9)
        case .unauthorized:
            return Color.red.opacity(0.9)
        default:
            return Color.red.opacity(0.85)
        }
    }
}

// MARK: - View Modifier for Easy Integration

extension View {
    /// Shows an error banner at the top of the view when error is present
    func errorBanner(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.overlay(alignment: .top) {
            if let currentError = error.wrappedValue {
                ErrorBannerView(
                    error: currentError,
                    onRetry: onRetry,
                    onDismiss: { error.wrappedValue = nil }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: error.wrappedValue != nil)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "022c22").ignoresSafeArea()
        
        VStack(spacing: 20) {
            ErrorBannerView(
                error: .network(message: ""),
                onRetry: { print("Retry") },
                onDismiss: { print("Dismiss") }
            )
            
            ErrorBannerView(
                error: .unauthorized,
                onRetry: nil,
                onDismiss: { print("Dismiss") }
            )
            
            ErrorBannerView(
                error: .serverError(statusCode: 500),
                onRetry: { print("Retry") },
                onDismiss: { print("Dismiss") }
            )
        }
    }
}
