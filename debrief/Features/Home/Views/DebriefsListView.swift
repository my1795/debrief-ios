//
//  HomeView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct DebriefsListView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var authSession: AuthSession // Passed for logout if needed (not used in HomeView UI directly but usually available)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
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
                            Text("Debriefs")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            // Status Bar
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Text("📝")
                                    Text("\(viewModel.stats.today)")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    Text("/")
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("📞")
                                    Text("\(viewModel.stats.total)")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Material.ultraThin)
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2), lineWidth: 1))
                                
                                HStack(spacing: 4) {
                                    Text("⏱️")
                                    Text("\(viewModel.stats.totalMins)")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    Text("min")
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Material.ultraThin)
                                .background(.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2), lineWidth: 1))
                            }
                            .font(.caption)
                        }
                        .padding(.top, 24)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color(hex: "5EEAD4")) // teal-300
                            TextField("", text: $viewModel.searchQuery, prompt: Text("Search debriefs...").foregroundColor(.white.opacity(0.4)))
                                .foregroundStyle(.white)
                                .onChange(of: viewModel.searchQuery) { _ in
                                    viewModel.filterDebriefs()
                                }
                        }
                        .padding(12)
                        .background(.white.opacity(0.1))
                        .background(Material.ultraThin)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredDebriefs) { debrief in
                                NavigationLink(destination: DebriefDetailView(debrief: debrief)) {
                                    DebriefCard(debrief: debrief)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80) // Space for TabBar
                    }
                }
            }
            .onAppear {
                viewModel.filterDebriefs()
            }
        }
    }
}

struct DebriefCard: View {
    let debrief: Debrief
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(debrief.contactName)
                    .font(.headline)
                    .foregroundStyle(.black)
                Spacer()
                StatusBadge(status: debrief.status)
            }
            
            // Meta
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(debrief.occurredAt.formatted(date: .abbreviated, time: .omitted))
                }
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(Int(debrief.duration / 60)) min")
                }
            }
            .font(.caption)
            .foregroundStyle(.gray)
            
            // Summary
            if let summary = debrief.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.gray.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Action Items
            if let items = debrief.actionItems, !items.isEmpty {
                Text("✓ \(items.count) action \(items.count == 1 ? "item" : "items")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
