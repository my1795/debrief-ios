//
//  Logger.swift
//  debrief
//
//  Centralized logging utility that respects environment settings.
//  Logs are only printed in LOCAL environment, disabled in Stage/Production.
//

import Foundation

/// Centralized logger that respects environment settings
enum Logger {

    /// Log levels for categorizing messages
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case success = "✅"
        case warning = "⚠️"
        case error = "❌"
        case network = "🌐"
        case auth = "🔐"
        case data = "📦"
        case sync = "🔄"
    }

    /// Whether logging is enabled (only in LOCAL environment)
    private static var isEnabled: Bool {
        AppConfig.shared.isVerboseLoggingEnabled
    }

    /// Main logging function
    static func log(
        _ message: String,
        level: Level = .info,
        file: String = #file
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        print("\(level.rawValue) [\(fileName)] \(message)")
    }

    // MARK: - Convenience Methods

    static func debug(_ message: String, file: String = #file) {
        log(message, level: .debug, file: file)
    }

    static func info(_ message: String, file: String = #file) {
        log(message, level: .info, file: file)
    }

    static func success(_ message: String, file: String = #file) {
        log(message, level: .success, file: file)
    }

    static func warning(_ message: String, file: String = #file) {
        log(message, level: .warning, file: file)
    }

    static func error(_ message: String, file: String = #file) {
        log(message, level: .error, file: file)
    }

    static func network(_ message: String, file: String = #file) {
        log(message, level: .network, file: file)
    }

    static func auth(_ message: String, file: String = #file) {
        log(message, level: .auth, file: file)
    }

    static func data(_ message: String, file: String = #file) {
        log(message, level: .data, file: file)
    }

    static func sync(_ message: String, file: String = #file) {
        log(message, level: .sync, file: file)
    }
}
