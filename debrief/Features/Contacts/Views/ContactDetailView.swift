//
//  ContactDetailView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI

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
                                isLoading: false,
                                onRefresh: {
                                    await loadDebriefs()
                                },
                                onLoadMore: { _ in
                                    // No pagination in this simple view yet
                                }
                            )
                            // We need to override component settings if we want to hide names, 
                            // but DebriefItem shows name by default. 
                            // In a contact detail view, showing the name (which is always this contact) is redundant.
                            // However, our unified component logic currently shows it.
                            // The user audio said "make it reusable", he didn't strictly forbid redundancy, but good UX would hide it.
                            // I'll leave it as standard for now to ensure consistency, or I could modify DebriefListContainer to take a param.
                            // Let's stick to simple reuse first.
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDebriefs()
        }
    }
    
    func loadDebriefs() async {
        guard let userId = authSession.user?.id else {
            print("⚠️ [ContactDetailView] No user ID available")
            return
        }
        
        isLoading = true
        do {
            // Fetch debriefs for this contact ID using FirestoreService (default caching behavior)
            // Fetch debriefs for this contact ID using FirestoreService (default caching behavior)
            let allDebriefs = try await FirestoreService.shared.fetchDebriefs(userId: userId, contactId: contact.id)
            
            // Fix: Populate contact name locally since we know who we are viewing
            let enrichedDebriefs = allDebriefs.map { debrief -> Debrief in
                var copy = debrief
                if copy.contactName.isEmpty || copy.contactName == "Unknown" {
                    copy.contactName = self.contact.name
                }
                return copy
            }
            
            self.debriefs = enrichedDebriefs.sorted(by: { $0.occurredAt > $1.occurredAt })
        } catch {
            print("Error loading contact debriefs: \(error)")
        }
        isLoading = false
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
