//
//  AppConfig.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 18/01/2026.
//

import Foundation

enum AppEnvironment {
    case local
    case production
}

struct AppConfig {
    static let shared = AppConfig()
    
    var currentEnvironment: AppEnvironment {
        #if DEBUG
        return .local
        #else
        return .production
        #endif
    }
    
    var apiBaseURL: String {
        switch currentEnvironment {
        case .local:
            return "http://localhost:8080/v1"
        case .production:
            // Placeholder: User to update this after backend deployment
            return "https://debrief-service-306744525686.us-central1.run.app/v1"
        }
    }
    
    private init() {}
}
