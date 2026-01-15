//
//  AppRootView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var authSession = AuthSession.shared
    
    var body: some View {
        Group {
            if authSession.isAuthenticated {
                MainTabView(authSession: authSession)
            } else {
                LoginView(authSession: authSession)
            }
        }
        .environmentObject(authSession)
        .animation(.easeInOut, value: authSession.isAuthenticated)
    }
}
