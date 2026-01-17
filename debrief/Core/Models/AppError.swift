//
//  AppError.swift
//  debrief
//
//  Created for Production Refactoring
//

import Foundation

/// Unified error type with user-facing messages.
/// Use this instead of raw errors to provide consistent UX.
enum AppError: Error, Identifiable, Equatable {
    case network(message: String)
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case unknown(message: String)
    
    var id: String { localizedDescription }
    
    /// User-friendly message to display in UI
    var userMessage: String {
        switch self {
        case .network:
            return "Unable to connect. Please check your internet connection."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .notFound:
            return "The requested content was not found."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unknown(let message):
            return message.isEmpty ? "An unexpected error occurred." : message
        }
    }
    
    /// Whether this error can be retried
    var isRetryable: Bool {
        switch self {
        case .network, .serverError:
            return true
        case .unauthorized, .notFound, .unknown:
            return false
        }
    }
    
    /// Icon for error display
    var icon: String {
        switch self {
        case .network:
            return "wifi.slash"
        case .unauthorized:
            return "lock.fill"
        case .notFound:
            return "magnifyingglass"
        case .serverError:
            return "exclamationmark.triangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create AppError from any Error
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        // Check for network errors
        if nsError.domain == NSURLErrorDomain {
            return .network(message: error.localizedDescription)
        }
        
        // Check for Firebase/Firestore errors
        if nsError.domain.contains("Firebase") || nsError.domain.contains("Firestore") {
            switch nsError.code {
            case 7: // PERMISSION_DENIED
                return .unauthorized
            case 5: // NOT_FOUND
                return .notFound
            default:
                return .serverError(statusCode: nsError.code)
            }
        }
        
        return .unknown(message: error.localizedDescription)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.network, .network): return true
        case (.unauthorized, .unauthorized): return true
        case (.notFound, .notFound): return true
        case (.serverError(let l), .serverError(let r)): return l == r
        case (.unknown(let l), .unknown(let r)): return l == r
        default: return false
        }
    }
}
