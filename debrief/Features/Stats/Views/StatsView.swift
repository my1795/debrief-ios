//
//  StatsView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedTab: StatsTab = .overview

    enum StatsTab: String, CaseIterable {
        case overview = "Overview"
        case charts = "Charts"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .overview: return "waveform.path.ecg"
            case .charts: return "chart.bar"
            case .insights: return "sparkles"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient (Teal/Emerald theme)
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
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Stats")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.top, 16)
                    
                    // Custom Segmented Picker
                    HStack(spacing: 8) {
                        ForEach(StatsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14))
                                    Text(tab.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTab == tab ? .white.opacity(0.2) : .white.opacity(0.05)
                                )
                                .foregroundStyle(
                                    selectedTab == tab ? .white : .white.opacity(0.6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:
                            StatsOverviewView(viewModel: viewModel)
                        case .charts:
                            ContentUnavailableView("Coming Soon", systemImage: "chart.bar", description: Text("Detailed charts are being built."))
                                .foregroundStyle(.white)
                                .frame(height: 300)
                        case .insights:
                            ContentUnavailableView("Coming Soon", systemImage: "sparkles", description: Text("AI Insights are generating."))
                                .foregroundStyle(.white)
                                .frame(height: 300)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}
