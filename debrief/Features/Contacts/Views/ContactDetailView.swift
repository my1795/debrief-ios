//
//  ContactDetailView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI
import FirebaseFirestore

struct ContactDetailView: View {
    let contact: Contact
    @State private var debriefs: [Debrief] = [] // Will fetch later
    @State private var isLoading = false
    @EnvironmentObject var authSession: AuthSession
    
    var body: some View {
        ZStack {
            // Background - Matching ContactsListView
            Color(hex: "134E4A").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
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
                    .padding(.top, 20)
                    
                    // Stats Grid
                    HStack(spacing: 12) {
                        DetailStatCard(title: "Debriefs", value: "\(debriefs.count)", icon: "mic.fill")
                        DetailStatCard(title: "Last Met", value: lastMetDate(), icon: "calendar")
                        DetailStatCard(title: "Duration", value: totalDurationString(), icon: "clock")
                    }
                    .padding(.horizontal)
                    
                    // Interactions History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Interaction History")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView().tint(.white)
                                Spacer()
                            }
                        } else if debriefs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("No recorded debriefs yet")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            // Reuse Unified Container
                            // We construct a single "history" section or just a standard section
                            // Note: TimelineViewModel usually handles grouping, but here we just have a flat list sorted by date.
                            // We can wrap it in a single section or refactor to group by date if desired.
                            // For minimal changes: Single Section.
                            
                            let section = TimelineViewModel.TimelineSection(
                                id: "history",
                                title: "", // No title needed for single section inside this view
                                date: Date(),
                                debriefs: debriefs
                            )
                            
                            DebriefListContainer(
                                sections: [section],
                                userId: authSession.user?.id ?? "",
                                isLoading: isFetching && debriefs.count > 0,
                                onRefresh: {
                                    await loadFirstPage()
                                },
                                onLoadMore: { debrief in
                                    // Trigger next page when scrolling near bottom
                                    let thresholdIndex = debriefs.count - 5
                                    if let index = debriefs.firstIndex(where: { $0.id == debrief.id }),
                                       index >= thresholdIndex {
                                        Task {
                                            await loadNextPage()
                                        }
                                    }
                                },
                                hideContactNames: true,
                                hasInternalScrollView: false
                            )
                        }
                    }
                }
            }
            .refreshable {
                await loadFirstPage()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if debriefs.isEmpty {
                await loadFirstPage()
            }
        }
    }
    
    // Pagination State
    @State private var lastDocument: DocumentSnapshot?
    @State private var hasMore = true
    @State private var isFetching = false
    private let pageSize = 20
    
    func loadFirstPage() async {
        guard !isFetching else { return }
        // Reset state
        lastDocument = nil
        hasMore = true
        // Only clear if we want a hard reset, but usually we keep existing for refresh feel until new data comes?
        // Standard pattern: clear if pull-to-refresh
        // If initial load, list is empty anyway.
        // Let's clear to be safe on explicit refresh.
        // debriefs = [] // Let's NOT clear yet to avoid UI flash on refresh, just replace on result.
        // Actually for correct pagination state reset we should clear or handle replacement carefully.
        // Simplest: Clear.
        if debriefs.isEmpty { isLoading = true }
        
        await loadNextPage(isRefreshing: true)
    }
    
    func loadNextPage(isRefreshing: Bool = false) async {
        guard let userId = authSession.user?.id else { return }
        guard (hasMore || isRefreshing) && (!isFetching || isRefreshing) else { return }
        
        // Critical: Set fetching flag after guard
        if isFetching && !isRefreshing { return } // Double safety against concurrent scroll triggers
        isFetching = true
        
        do {
            let filters = DebriefFilters(contactId: contact.id)
            
            let result = try await FirestoreService.shared.fetchDebriefs(
                userId: userId,
                filters: filters,
                limit: pageSize,
                startAfter: isRefreshing ? nil : lastDocument
            )
            
            // Enrich contact name locally since we know who we are viewing
            let enrichedDebriefs = result.debriefs.map { debrief -> Debrief in
                var copy = debrief
                if copy.contactName.isEmpty || copy.contactName == "Unknown" {
                    copy.contactName = self.contact.name
                }
                return copy
            }
            
            if isRefreshing {
                self.debriefs = enrichedDebriefs
                self.lastDocument = result.lastDocument
                self.hasMore = result.debriefs.count == pageSize
            } else {
                // Determine if we actually had new items to avoid infinite spinner if backend returns empty but hasMore was true?
                if !enrichedDebriefs.isEmpty {
                    self.debriefs.append(contentsOf: enrichedDebriefs)
                    self.lastDocument = result.lastDocument
                    self.hasMore = result.debriefs.count == pageSize
                } else {
                    self.hasMore = false
                }
            }
            
        } catch {
            print("❌ [ContactDetailView] Error loading debriefs: \(error)")
        }
        
        isLoading = false
        isFetching = false
    }
    
    func totalDurationString() -> String {
        let totalSeconds = Int(debriefs.reduce(0) { $0 + $1.duration })
        if totalSeconds == 0 { return "0s" }
        
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }
        
        let minutes = totalSeconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
    }
    
    func lastMetDate() -> String {
        guard let last = debriefs.first?.occurredAt else { return "-" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: last, relativeTo: Date())
    }
    
    func statusColor(_ status: DebriefStatus) -> Color {
        switch status {
        case .ready: return .green
        case .processing: return .yellow
        case .failed: return .red
        default: return .gray
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

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.teal)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
