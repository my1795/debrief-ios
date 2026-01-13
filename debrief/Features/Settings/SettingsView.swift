//
//  SettingsView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authSession: AuthSession
    
    var body: some View {
        ZStack {
            Color(hex: "115E59").ignoresSafeArea()
            
            VStack {
                Text("Settings Screen")
                    .foregroundStyle(.white)
                    .padding()
                
                Button(action: {
                    authSession.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
    }
}
