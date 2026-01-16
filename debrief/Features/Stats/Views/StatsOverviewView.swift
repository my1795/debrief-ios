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
            HStack {
                Text("Weekly Stats")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("(Sun - Sun)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Use the calculated Weekly Stats from ViewModel
                ForEach(viewModel.stats) { stat in
                    MetricCard(
                        title: stat.title,
                        value: stat.value,
                        icon: stat.icon,
                        trendString: stat.subValue,
                        infoText: getInfoText(for: stat.title)
                    )
                }
            }
            
            // MARK: - Quick Stats List
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    QuickStatRow(
                        icon: "clock",
                        color: .teal,
                        title: "Avg Duration",
                        value: formatAvgDuration(viewModel.overview.avgDebriefDuration),
                        subtitle: "Per Debrief (This Week)",
                        infoText: "Average length of your debriefs recorded this week."
                    )
                    QuickStatRow(
                        icon: "checklist", // Tasks icon
                        color: .green,
                        title: "Tasks Created",
                        value: "\(viewModel.overview.totalActionItems)",
                        subtitle: "Action Items (This Week)",
                        infoText: "Total number of action items automatically extracted from your debriefs this week."
                    )
                    QuickStatRow(
                        icon: "calendar",
                        color: .orange,
                        title: "Most Active Day",
                        value: viewModel.overview.mostActiveDay,
                        subtitle: "This Week",
                        infoText: "The day of the week you recorded the most debriefs."
                    )
                    QuickStatRow(
                        icon: "flame.fill",
                        color: .red,
                        title: "Longest Streak",
                        value: "\(viewModel.overview.longestStreak) hrs",
                        subtitle: "Consecutive Hours",
                        infoText: "The longest sequence of consecutive hours where you recorded at least one debrief."
                    )
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
                        percent: viewModel.recordingsQuotaPercent,
                        subLabel: "this week"
                    )
                    
                    QuotaRow(
                        title: "Minutes",
                        current: viewModel.quota.minutesThisMonth,
                        limit: viewModel.quota.minutesLimit,
                        percent: viewModel.minutesQuotaPercent,
                        subLabel: "min this week"
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
                    Text("Top Contacts (This Week)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }
                
                if viewModel.isLoadingTopContacts && viewModel.topContacts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Calculating...")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if viewModel.topContacts.isEmpty {
                    Text("No contacts this week")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.topContacts.enumerated()), id: \.element.id) { index, contact in
                            NavigationLink(destination: ContactDetailView(contact: Contact(
                                id: contact.id,
                                name: contact.name == "Unknown Contact" ? "Deleted User" : contact.name,
                                handle: contact.company == "External" ? nil : contact.company,
                                totalDebriefs: contact.debriefs
                            ))) {
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
                                        HStack(spacing: 4) {
                                            Text(contact.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            
                                            // Handle "Unknown" or deleted case
                                            if contact.name == "Unknown Contact" {
                                                Text("- Deleted")
                                                    .font(.caption)
                                                    .foregroundStyle(.red.opacity(0.8))
                                            }
                                        }
                                        
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
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
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
    func getInfoText(for title: String) -> String {
        switch title {
        case "Total Debriefs": return "Total number of debriefs recorded this week."
        case "Duration per Week": return "Total duration of all debriefs recorded this week."
        case "Action Items": return "Total number of action items identified in your debriefs this week."
        case "Active Contacts": return "Number of unique people you have debriefed about this week."
        default: return "Weekly statistic comparison."
        }
    }
    
    func formatAvgDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) sec"
        } else if seconds < 600 { // 10 minutes * 60
             let minutes = Int(seconds) / 60
             let secs = Int(seconds) % 60
             return String(format: "%d:%02d min", minutes, secs)
        } else {
            return "\(Int(round(seconds / 60))) min"
        }
    }
}

// MARK: - Subviews

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: Double? = nil
    var trendString: String? = nil // Support pre-formatted strings (e.g. "+100%", "Infinite")
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
            
            if let trendString = trendString {
                 HStack(spacing: 4) {
                     // Simple heuristic: if it starts with "+", green. If "-", red.
                     let isPositive = trendString.hasPrefix("+")
                     let isNegative = trendString.hasPrefix("-")
                     
                     if isPositive {
                         Image(systemName: "arrow.up.right")
                     } else if isNegative && trendString != "- 0.0%" {
                         Image(systemName: "arrow.down.right")
                     }
                     Text(trendString)
                 }
                 .font(.caption.bold())
                 .foregroundStyle(trendString.hasPrefix("+") ? .green : (trendString == "- 0.0%" ? .white.opacity(0.6) : .red))
                 
            } else if let trend = trend {
                HStack(spacing: 4) {
                    if abs(trend) < 0.1 {
                        Text("-")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                        Text("0.0%")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(String(format: "%.1f", abs(trend)))%")
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(abs(trend) < 0.1 ? .white.opacity(0.6) : (trend > 0 ? .green : .red))
            } else if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 150) // Fixed height to ensure all cards are equal
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
    var subtitle: String? = nil
    var infoText: String? = nil
    @State private var showInfo = false
    
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
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
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
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
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
    var subLabel: String? = nil // e.g. "this week"
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(current) / \(limit) \(unit)\(subLabel != nil ? " " + subLabel! : "")")
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
