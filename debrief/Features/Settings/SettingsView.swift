//
//  SettingsView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authSession: AuthSession
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Title
                        HStack {
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Privacy First Banner
                        PrivacyBanner()
                            .padding(.horizontal)
                        
                        // Account Section
                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "person.circle.fill", title: "Profile", value: authSession.user?.email ?? "User")
                        }
                        
                        // Plan Section
                        SettingsSection(title: "Plan") {
                            SettingsRow(icon: "star.circle.fill", title: "Current Plan", value: "Free")
                            
                            NavigationLink(destination: UsageView(viewModel: viewModel)) {
                                SettingsRow(icon: "chart.bar.fill", title: "Billing History", value: "Usage", showChevron: true)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            ToggleRow(icon: "bell.fill", title: "Notifications", isOn: $viewModel.notificationsEnabled)
                        }
                        
                        // Privacy & Support Section
                        SettingsSection(title: "Privacy & Support") {
                            Button {
                                viewModel.openPrivacyPolicy()
                            } label: {
                                SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", showChevron: true)
                            }
                            
                            SettingsRow(icon: "lock.shield.fill", title: "Data Handling", value: "More Info", showChevron: true)
                            
                            Button {
                                viewModel.openHelpCenter()
                            } label: {
                                SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", showChevron: true)
                            }
                        }
                        
                        // Storage Section
                        SettingsSection(title: "Storage") {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "internaldrive.fill")
                                        .foregroundStyle(Color.teal)
                                    Text("Storage Used")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(viewModel.cacheSize)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                
                                Button(action: {
                                    viewModel.clearCache()
                                }) {
                                    Text("Clear Cache")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color(hex: "FECACA"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // App Version
                        Text("Debrief AI \(viewModel.appVersion)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.top, 8)
                        
                        // Sign Out Button (Bottom)
                        Button(action: {
                            authSession.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white) // White text on Red background usually looks better
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.9)) // Solid red
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Subviews

struct PrivacyBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "shield.check.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "5EEAD4")) // teal-300
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy First")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Your recordings are processed locally and encrypted. We never listen to your audio.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [Color(hex: "134E4A"), Color(hex: "0F766E")], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "5EEAD4").opacity(0.3), lineWidth: 1)
        )
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 16)
            
            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundStyle(Color(hex: "2DD4BF")) // teal-400
            
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.caption)
            }
        }
        .padding(.vertical, 12)
        // Add divider logic if needed, but spacing usually enough in clean designs
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundStyle(Color(hex: "2DD4BF")) // teal-400
            
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "2DD4BF"))
        }
        .padding(.vertical, 8)
    }
}

// Simple Subview for Usage
struct UsageView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "115E59").ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Billing History")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    Text("Total Usage Cost")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(viewModel.usageCost)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(40)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}
