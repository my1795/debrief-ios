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
    @State private var showEducation = false

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
        NavigationView {
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
                            InfoButton(topic: EducationTopics.stats, showEducation: $showEducation)
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
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Coming Soon")
                                        .font(.title2)
                                        .bold()
                                        .foregroundStyle(.white)
                                    Text("Detailed charts are being built.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                                
                            case .insights:
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Coming Soon")
                                        .font(.title2)
                                        .bold()
                                        .foregroundStyle(.white)
                                    Text("AI Insights are generating.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 300)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadData()
        }
        .errorBanner(error: $viewModel.error, onRetry: {
            Task { await viewModel.loadData() }
        })
    }
}
