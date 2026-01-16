//
//  StatusBadge.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct StatusBadge: View {
    let status: DebriefStatus
    var showIcon: Bool = true
    
    var config: StatusConfig {
        switch status {
        case .draft:
            return StatusConfig(label: "Draft", bgColor: .gray.opacity(0.1), fgColor: .gray, borderColor: .gray.opacity(0.3), icon: "clock")
        case .uploaded, .created:
            return StatusConfig(label: "Uploading", bgColor: .blue.opacity(0.1), fgColor: .blue, borderColor: .blue.opacity(0.3), icon: "arrow.up.circle")
        case .processing:
            return StatusConfig(label: "Processing", bgColor: .yellow.opacity(0.1), fgColor: .yellow, borderColor: .yellow.opacity(0.3), icon: "arrow.triangle.2.circlepath")
        case .ready:
            return StatusConfig(label: "Ready", bgColor: .green.opacity(0.1), fgColor: .green, borderColor: .green.opacity(0.3), icon: "checkmark.circle")
        case .failed:
            return StatusConfig(label: "Failed", bgColor: .red.opacity(0.1), fgColor: .red, borderColor: .red.opacity(0.3), icon: "xmark.circle")
        }
    }
    
    struct StatusConfig {
        let label: String
        let bgColor: Color
        let fgColor: Color
        let borderColor: Color
        let icon: String
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                if #available(iOS 17.0, *) {
                    Image(systemName: config.icon)
                        .font(.system(size: 10))
                        .symbolEffect(.pulse, isActive: status == .processing)
                } else {
                    Image(systemName: config.icon)
                        .font(.system(size: 10))
                }
            }
            Text(config.label)
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(config.bgColor)
        .foregroundStyle(config.fgColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(config.borderColor, lineWidth: 1)
        )
    }
}
