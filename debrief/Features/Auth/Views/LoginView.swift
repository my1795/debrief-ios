//
//  LoginView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authSession: AuthSession
    
    var body: some View {
        ZStack {
            // Background Gradient: from-teal-900 via-teal-800 to-emerald-900
            LinearGradient(
                colors: [
                    Color(hex: "134E4A"), // teal-900
                    Color(hex: "115E59"), // teal-800
                    Color(hex: "064E3B")  // emerald-900
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo/Brand
                VStack(spacing: 16) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    .padding(.bottom, 16)
                    
                    Text("Debrief")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Voice memos that work for you")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 48)
                
                // Sign In Card
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Welcome")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("Sign in to start recording your debriefs")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                    
                    // Google Sign In Button
                    Button {
                        Task {
                            await authSession.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if authSession.isLoading {
                                ProgressView()
                                    .tint(.black)
                                Text("Signing in...")
                            } else {
                                Image(systemName: "globe") // Fallback for Chrome icon
                                Text("Continue with Google")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authSession.isLoading)
                    
                    if let error = authSession.error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // Privacy Notice
                    HStack(spacing: 8) {
                        Text("🔐")
                        Text("Your privacy matters. All recordings are encrypted and only accessible by you.")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(AppTheme.Colors.selection.opacity(0.1)) // teal-400 equivalent
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1) // teal-300
                    )
                    .foregroundStyle(Color(hex: "99F6E4")) // teal-200 (Use theme if available, else keep hex or add to theme)
                }
                .padding(32)
                .background(.white.opacity(0.1))
                .background(Material.ultraThin) // simple blur
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Footer
                VStack(spacing: 4) {
                    Text("By signing in, you agree to our")
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            if let url = AppConfig.shared.termsOfServiceURL {
                                UIApplication.shared.open(url)
                            }
                        }
                        Text("•")
                        Button("Privacy Policy") {
                            if let url = AppConfig.shared.privacyPolicyURL {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .foregroundStyle(Color(hex: "5EEAD4")) // teal-300
                }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 24)
                
                Text("Debrief v1.0.0")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 16)
            }
        }
    }
}

