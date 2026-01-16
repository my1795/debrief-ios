//
//  TimelineView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
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
                            Text("Timeline")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Daily Stats Pill
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("📝")
                                    Text("\(viewModel.dailyStats.todayDebriefs)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text("/")
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("📞")
                                    Text("\(viewModel.dailyStats.todayCalls)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                HStack(spacing: 4) {
                                    Text("⏱️")
                                    Text("\(viewModel.dailyStats.todayMins)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text("min")
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        SearchBar(text: $viewModel.searchText)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                    .background(Color(hex: "022c22"))
                    
                    // Infinite Scroll Feed
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                            
                            ForEach(viewModel.sections) { section in
                                Section {
                                    ForEach(section.debriefs) { debrief in
                                        NavigationLink(destination: DebriefDetailView(debrief: debrief, userId: userId)) {
                                            TimelineCard(debrief: debrief)
                                                .onAppear {
                                                    viewModel.loadMoreIfNeeded(currentItem: debrief, userId: userId)
                                                }
                                        }
                                        .buttonStyle(.plain) // Prevent blue tint on card
                                    }
                                } header: {
                                    Text(section.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(Color(hex: "022c22").opacity(0.95)) // Stickiness 
                                }
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding()
                            }
                            
                            // Spacer at bottom
                            Color.clear.frame(height: 80)
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        await viewModel.loadData(userId: userId, refresh: true)
                    }
                }
            }
            .onAppear {
                if viewModel.debriefs.isEmpty {
                    Task {
                        await viewModel.loadData(userId: userId)
                        await viewModel.loadDailyStats(userId: userId)
                    }
                }
            }
        }
    }
}

// Simple Card for Phase 1
struct TimelineCard: View {
    let debrief: Debrief
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Name + Time + Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(debrief.contactName.isEmpty ? "Unknown" : debrief.contactName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(debrief.occurredAt.formatted(date: .omitted, time: .shortened))
                        Text("•")
                        Text("\(Int(debrief.duration / 60)) min")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Status Pill (Mini)
                if debrief.status != .ready {
                    Text(debrief.status.rawValue.capitalized)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
            
            // Summary Preview
            if let summary = debrief.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            } else {
                Text(debrief.transcript ?? "No summary available")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
            
            // Footer: Action Items
            if let items = debrief.actionItems, !items.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .foregroundColor(.orange)
                    Text("\(items.count) action items")
                        .foregroundColor(.orange)
                }
                .font(.caption.weight(.medium))
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
