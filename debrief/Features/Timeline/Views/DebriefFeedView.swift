//
//  TimelineView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import SwiftUI

struct DebriefFeedView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @State private var showFilters = false
    @State private var showSearch = false
    let userId: String // Passed from parent
    
    // For Phase 1: Search is visual or basic local filter (placeholder)
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "022c22").ignoresSafeArea() // dark-bg
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Text("Debriefs") // Renamed from Timeline
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Daily Stats Pill
                            GroupedStatsPillView(
                                leftItems: [("mic.fill", "\(viewModel.dailyStats.todayDebriefs)"), ("phone.fill", "\(viewModel.dailyStats.todayCalls)")],
                                rightItems: [("clock", formatDuration(viewModel.dailyStats.todayDuration), nil)],
                                infoTitle: "Daily Stats (Today)",
                                infoDetails: [
                                    ("mic.fill", "Total debriefs recorded"),
                                    ("phone.fill", "Total calls logged"),
                                    ("clock", "Total duration of interactions")
                                ]
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        HStack(spacing: 10) {
                            // Semantic Search Button (Replacing local SearchBar)
                            Button {
                                showSearch = true
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color.white.opacity(0.6))
                                    Text("Search debriefs...")
                                        .foregroundColor(Color.white.opacity(0.6))
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            Button {
                                showFilters = true
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20)) // Bigger icon
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .overlay(
                                        Group {
                                            if viewModel.filters.isActive {
                                                Circle()
                                                    .fill(Color.orange)
                                                    .frame(width: 10, height: 10)
                                                    .offset(x: 14, y: -14)
                                            }
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Active Filters
                        ActiveFilterChips(filters: $viewModel.filters) { newFilters in
                            Task {
                                await viewModel.applyFilters(newFilters, userId: userId)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .background(Color(hex: "022c22"))
                    
                    // Unified List Container using DebriefListContainer
                    VStack(spacing: 0) {
                        // Only show Recent People if no contact filter active
                        if viewModel.filters.contactId == nil && !viewModel.recentContacts.isEmpty {
                            RecentPeopleStrip(contacts: viewModel.recentContacts) { contact in
                                var newFilters = viewModel.filters
                                newFilters.contactId = contact.id
                                newFilters.contactName = contact.name // Ensure name is set
                                Task {
                                    await viewModel.applyFilters(newFilters, userId: userId)
                                }
                            }
                            .padding(.bottom, 8)
                            .background(Color(hex: "022c22"))
                        }
                        
                        DebriefListContainer(
                            sections: viewModel.sections,
                            userId: userId,
                            isLoading: viewModel.isLoading,
                            onRefresh: {
                                await viewModel.loadData(userId: userId, refresh: true)
                            },
                            onLoadMore: { debrief in
                                viewModel.loadMoreIfNeeded(currentItem: debrief, userId: userId)
                            }
                        )
                    }
                }
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView()
            }
            .onAppear {
                if viewModel.debriefs.isEmpty {
                    Task {
                        await viewModel.loadData(userId: userId)
                        await viewModel.loadDailyStats(userId: userId)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filters: $viewModel.filters, isPresented: $showFilters) { newFilters in
                    Task {
                        await viewModel.applyFilters(newFilters, userId: userId)
                    }
                }
            }
            .errorBanner(error: $viewModel.error, onRetry: {
                Task { await viewModel.loadData(userId: userId, refresh: true) }
            })
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let d = max(0, duration)
        if d < 60 {
            return "\(Int(d))s"
        } else {
            return "\(Int(d / 60)) min"
        }
    }
}
