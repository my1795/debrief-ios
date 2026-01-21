//
//  AppConfig.swift
//  debrief
//
//  Multi-environment configuration: Local, Stage, Production
//

import Foundation

/// App environment types
enum AppEnvironment: String {
    case local
    case stage
    case production
    
    var displayName: String {
        switch self {
        case .local: return "Local"
        case .stage: return "Stage"
        case .production: return "Production"
        }
    }
}

/// Central configuration for environment-specific settings
struct AppConfig {
    static let shared = AppConfig()
    
    /// Current environment - read from Info.plist or fallback to compile-time detection
    var currentEnvironment: AppEnvironment {
        // First, try to read from Info.plist (set by Build Configuration)
        if let envString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String,
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }
        
        // Fallback to compile-time detection based on compiler flags
        #if STAGE
        return .stage
        #elseif DEBUG
        return .local
        #else
        return .production
        #endif
    }
    
    /// Backend API base URL
    var apiBaseURL: String {
        switch currentEnvironment {
        case .local:
            return "http://localhost:8080/v1"
        case .stage:
            return "https://debrief-service-306744525686.us-central1.run.app/v1"
        case .production:
            return "https://debrief-service-109210365587.us-central1.run.app/v1"
        }
    }
    
    /// Firebase configuration file name (without .plist extension)
    var firebaseConfigFileName: String {
        switch currentEnvironment {
        case .local, .stage:
            return "GoogleService-Dev"
        case .production:
            return "GoogleService-Prod"
        }
    }
    
    /// Whether this is a development environment
    var isDevelopment: Bool {
        currentEnvironment == .local || currentEnvironment == .stage
    }
    
    /// Whether verbose logging should be enabled (LOCAL only, not stage or production)
    var isVerboseLoggingEnabled: Bool {
        currentEnvironment == .local
    }
    
    private init() {
        // Log current environment on init
        print("🌍 [AppConfig] Environment: \(currentEnvironment.displayName)")
        print("📡 [AppConfig] API Base URL: \(apiBaseURL)")
    }
}
