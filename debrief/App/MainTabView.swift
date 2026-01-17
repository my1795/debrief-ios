//
//  MainTabView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

enum AppTab {
    case debriefs
    case stats
    case record // Logic specific handling
    case contacts
    case settings
}

struct MainTabView: View {
    @ObservedObject var authSession: AuthSession
    @State private var selectedTab: AppTab = .debriefs
    @State private var showRecordSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .debriefs:
                    DebriefFeedView(userId: authSession.user?.id ?? "")
                case .stats:
                    StatsView()
                case .record:
                    Color.clear // Not reachable via normal tab
                case .contacts:
                    ContactsView()
                case .settings:
                    SettingsView(authSession: authSession)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Bottom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, onRecordTap: {
                showRecordSheet = true
            })
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showRecordSheet) {
            RecordView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    var onRecordTap: () -> Void
    
    var body: some View {
        HStack {
            // Debriefs
            TabBarButton(icon: "doc.text", label: "Debriefs", isSelected: selectedTab == .debriefs) {
                selectedTab = .debriefs
            }
            
            Spacer()
            
            // Stats
            TabBarButton(icon: "chart.bar", label: "Stats", isSelected: selectedTab == .stats) {
                selectedTab = .stats
            }
            
            Spacer()
            
            // RECORD BUTTON (Prominent)
            Button(action: onRecordTap) {
                ZStack {
                    Circle()
                        .fill(Color.red) // FIGMA: Red color for Record
                        .frame(width: 56, height: 56)
                        .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                    }
                    .foregroundColor(.white)
                }
            }
            .offset(y: -24) // Pop out effect
            
            Spacer()
            
            // Contacts
            TabBarButton(icon: "person.2", label: "Contacts", isSelected: selectedTab == .contacts) {
                selectedTab = .contacts
            }
            
            Spacer()
            
            // Settings
            TabBarButton(icon: "gearshape", label: "Settings", isSelected: selectedTab == .settings) {
                selectedTab = .settings
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // Adjust for Home Indicator
        .padding(.top, 12)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .blue : .gray) // FIGMA: Active uses blue-600 logic, inactive gray
        }
    }
}
