//
//  HapticService.swift
//  debrief
//
//  Created for Phase 5 UX Polish
//

import UIKit

/// Centralized haptic feedback service for consistent tactile feedback.
enum HapticService {
    
    // MARK: - Impact Feedback
    
    /// Light impact (e.g., button taps, selection changes)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact (e.g., toggle switches, pull-to-refresh)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact (e.g., completing recording, major actions)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification (e.g., upload complete, save successful)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification (e.g., approaching limit)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification (e.g., failed action)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed (e.g., picker, segment control)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
