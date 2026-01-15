//
//  DebriefRowView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI

struct DebriefRowView: View {
    let debrief: Debrief
    var showContactName: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if showContactName {
                    Text(debrief.contactName.isEmpty ? "Unknown" : debrief.contactName)
                        .font(.headline)
                        .foregroundStyle(.black)
                } else {
                    // In Contact Detail context, show Date prominently in header
                    Text(debrief.occurredAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                StatusBadge(status: debrief.status)
            }
            
            // Meta Information
            HStack(spacing: 16) {
                // If Name is shown in header, show Date here.
                if showContactName {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(debrief.occurredAt.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                
                // Duration is always shown
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
            } else {
                Text(debrief.transcript ?? "No summary available")
                    .font(.system(.subheadline, design: .default).italic())
                    .foregroundStyle(.gray.opacity(0.5))
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
