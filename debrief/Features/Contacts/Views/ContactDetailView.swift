//
//  ContactDetailView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI
import FirebaseFirestore

struct ContactDetailView: View {
    @StateObject private var viewModel: ContactDetailViewModel
    @EnvironmentObject var authSession: AuthSession
    @State private var showFilterSheet = false
    @State private var showScrollToTop = false
    
    init(contact: Contact) {
        _viewModel = StateObject(wrappedValue: ContactDetailViewModel(contact: contact))
    }
    
    var body: some View {
        ZStack {
            // Background - Matching ContactsListView
            Color(hex: "134E4A").ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    // Anchor
                    GeometryReader { geo in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("detailScroll")).minY)
                    }
                    .frame(height: 0)
                    .id("top")
                    
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeader(contact: viewModel.contact)
                            .padding(.top, 20)
                        
                        HStack(spacing: 12) {
                            DetailStatCard(
                                title: "Debriefs",
                                value: "\(viewModel.totalDebriefsCount)",
                                icon: "mic.fill",
                                color: .teal,
                                infoText: "Total debriefs recorded. (Sunday-to-Sunday if 'This Week' selected)"
                            )
                            DetailStatCard(
                                title: "Last Met",
                                value: viewModel.lastMetString,
                                icon: "calendar",
                                color: .teal,
                                infoText: "The date of your most recent debrief with this contact."
                            )
                            DetailStatCard(
                                title: "Duration",
                                value: "\(viewModel.totalDurationMinutes)m",
                                icon: "clock",
                                color: .teal,
                                infoText: "Total duration of recorded debriefs for the selected period."
                            )
                        }
                        .padding(.horizontal)
                        
                        // Search & Filters
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                SearchBar(text: $viewModel.searchText)
                                
                                Button {
                                    showFilterSheet = true
                                } label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                        .overlay(
                                            Group {
                                                if viewModel.filters.dateOption != .all || viewModel.filters.hasActionItems {
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
                            

                        }
                        
                        // Interactions History
                        Text("Interaction History")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(.white)
                                    Spacer()
                                }
                            } else if viewModel.debriefs.isEmpty && !viewModel.isLoading {
                                EmptyStateView.noDebriefs()
                            } else {
                                // List
                                let section = TimelineViewModel.TimelineSection(
                                    id: "history",
                                    title: "", 
                                    date: Date(),
                                    debriefs: viewModel.displayedDebriefs
                                )
                                
                                DebriefListContainer(
                                    sections: [section],
                                    userId: authSession.user?.id ?? "",
                                    isLoading: false, 
                                    onRefresh: {
                                        await viewModel.loadData(refresh: true)
                                    },
                                    onLoadMore: { item in
                                        if let idx = viewModel.debriefs.firstIndex(where: { $0.id == item.id }), idx >= viewModel.debriefs.count - 5 {
                                            Task { await viewModel.loadData(refresh: false) }
                                        }
                                    },
                                    hideContactNames: true,
                                    hasInternalScrollView: false
                                )
                            }
                        }
                    }

                .coordinateSpace(name: "detailScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation { showScrollToTop = value < -300 }
                }
                .overlay(alignment: .bottomTrailing) {
                    if showScrollToTop {
                        ScrollToTopButton {
                            withAnimation { proxy.scrollTo("top", anchor: .top) }
                        }
                    }
                }
                .refreshable {
                    await viewModel.loadData(refresh: true)
                }
            }
        }
        .errorBanner(error: $viewModel.error, onRetry: {
            Task { await viewModel.loadData(refresh: true) }
        })
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.debriefs.isEmpty {
                await viewModel.loadData(refresh: true)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                filters: $viewModel.filters,
                isPresented: $showFilterSheet,
                allowContactSelection: false
            ) { newFilters in
                viewModel.filters = newFilters
                Task {
                    await viewModel.loadData(refresh: true)
                }
            }
        }
    }
}

// Helper Views
struct ProfileHeader: View {
    let contact: Contact
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "2DD4BF"), Color(hex: "0D9488")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(getInitials(name: contact.name))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            Text(contact.name)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
            
            if let handle = contact.handle {
                Text(handle)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    func getInitials(name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "?" }
        let first = parts[0].prefix(1)
        let last = parts.count > 1 ? parts[1].prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

struct QuickFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .foregroundColor(isSelected ? Color.black : Color.white)
                .clipShape(Capsule())
        }
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var infoText: String? = nil
    
    @State private var showInfo = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                if let info = infoText {
                    Button(action: { showInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .alert(isPresented: $showInfo) {
                        Alert(title: Text(title), message: Text(info), dismissButton: .default(Text("OK")))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
