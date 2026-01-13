//
//  StatsOverviewView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI

struct StatsOverviewView: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Current Plan Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Current Plan")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Text(viewModel.quota.tier)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Limited access")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0891B2"), Color(hex: "06B6D4")], // cyan-600 to cyan-500 (Free/Starter look)
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            
            // MARK: - Key Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Total Debriefs",
                    value: "\(viewModel.overview.totalDebriefs)",
                    icon: "mic.fill",
                    trend: viewModel.trends.debriefsChangePercent,
                    infoText: "Debriefs created this month vs last month"
                )
                
                MetricCard(
                    title: "Total Minutes",
                    value: "\(viewModel.overview.totalMinutes)",
                    icon: "clock.fill",
                    trend: viewModel.trends.minutesChangePercent,
                    infoText: "Total recording time vs last month"
                )
                
                MetricCard(
                    title: "Action Items",
                    value: "\(viewModel.overview.totalActionItems)",
                    icon: "checklist",
                    trend: viewModel.trends.actionItemsChangePercent,
                    infoText: "Action items generated vs last month"
                )
                
                MetricCard(
                    title: "Contacts",
                    value: "\(viewModel.overview.totalContacts)",
                    icon: "person.2.fill",
                    detail: "Active contacts",
                    infoText: "Contacts with at least one debrief"
                )
            }
            
            // MARK: - Quick Stats List
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    QuickStatRow(icon: "clock", color: .teal, title: "Avg Duration", value: "\(viewModel.overview.avgDebriefDuration) min")
                    QuickStatRow(icon: "target", color: .green, title: "Completion Rate", value: "\(viewModel.overview.completionRate)%")
                    QuickStatRow(icon: "calendar", color: .orange, title: "Most Active Day", value: viewModel.overview.mostActiveDay)
                    QuickStatRow(icon: "flame.fill", color: .red, title: "Longest Streak", value: "\(viewModel.overview.longestStreak) days")
                }
            }
            .padding()
            .background(.white.opacity(0.1))
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))

            // MARK: - Quota Usage
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.teal)
                    Text("Quota Usage")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 16) {
                    QuotaRow(
                        title: "Recordings",
                        current: viewModel.quota.recordingsThisMonth,
                        limit: viewModel.quota.recordingsLimit,
                        percent: viewModel.recordingsQuotaPercent
                    )
                    
                    QuotaRow(
                        title: "Minutes",
                        current: viewModel.quota.minutesThisMonth,
                        limit: viewModel.quota.minutesLimit,
                        percent: viewModel.minutesQuotaPercent
                    )
                    
                    QuotaRow(
                        title: "Storage",
                        current: viewModel.quota.storageUsedMB,
                        limit: viewModel.quota.storageLimitMB,
                        percent: viewModel.storageQuotaPercent,
                        unit: "MB"
                    )
                }
            }
            .padding()
            .background(.white.opacity(0.1))
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
            
            // MARK: - Top Contacts
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.teal)
                    Text("Top Contacts")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("View All") { }
                        .font(.caption)
                        .foregroundStyle(.teal)
                }
                
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.topContacts.enumerated()), id: \.element.id) { index, contact in
                        HStack(spacing: 12) {
                            // Rank Circle
                            ZStack {
                                Circle()
                                    .fill(Color.teal.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                Text("#\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.teal)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                Text(contact.company)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(contact.debriefs)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Text("\(contact.minutes)m")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(.white.opacity(0.1))
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - Subviews

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: Double? = nil
    var detail: String? = nil
    @State private var showInfo = false
    var infoText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Color.teal)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                
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
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(String(format: "%.1f", abs(trend)))%")
                }
                .font(.caption.bold())
                .foregroundStyle(trend > 0 ? .green : .red)
            } else if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .background(Material.ultraThin)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
    }
}

struct QuickStatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
    }
}

struct QuotaRow: View {
    let title: String
    let current: Int
    let limit: Int
    let percent: Double
    var unit: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(current) / \(limit) \(unit)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(percent > 0.8 ? Color.red : Color.teal)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(percent), geometry.size.width)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
