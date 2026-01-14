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
                        DetailStatCard(title: "Minutes", value: "\(totalMinutes())", icon: "clock")
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
                            LazyVStack(spacing: 12) {
                                ForEach(debriefs) { debrief in
                                    // Reuse the shared component, hiding name since we are in that contact's detail
                                    // And enable NAVIGATION to the full detail view
                                    NavigationLink(destination: DebriefDetailView(debrief: debrief)) {
                                        DebriefRowView(debrief: debrief, showContactName: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
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
        isLoading = true
        do {
            // Fetch debriefs for this contact ID
            // Ideally, backend supports filtering by contactId.
            // Using APIService.shared.getDebriefs(contactId: contact.id)
            let allDebriefs = try await APIService.shared.getDebriefs(contactId: contact.id)
            self.debriefs = allDebriefs.sorted(by: { $0.occurredAt > $1.occurredAt })
        } catch {
            print("Error loading contact debriefs: \(error)")
        }
        isLoading = false
    }
    
    func totalMinutes() -> Int {
        let seconds = debriefs.reduce(0) { $0 + $1.duration }
        return Int(seconds / 60)
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
