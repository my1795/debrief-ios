import SwiftUI

struct DebriefItem: View {
    let debrief: Debrief
    var showContactName: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Name + Time + Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if showContactName {
                        Text(debrief.contactName.isEmpty ? "Unknown" : debrief.contactName)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(debrief.occurredAt.formatted(date: .omitted, time: .shortened))
                        Text("•")
                        if debrief.duration < 60 {
                            Text("\(Int(debrief.duration))s")
                        } else {
                            Text("\(Int(debrief.duration / 60)) min")
                        }
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
