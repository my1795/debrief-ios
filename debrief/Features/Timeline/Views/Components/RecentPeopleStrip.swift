//
//  RecentPeopleStrip.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import SwiftUI

struct RecentPeopleStrip: View {
    let contacts: [Contact]
    let onSelect: (Contact) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent People")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(contacts) { contact in
                        Button {
                            onSelect(contact)
                        } label: {
                            VStack(spacing: 6) {
                                ContactAvatar(name: contact.name, size: 48)
                                    // Custom style for dark mode strip
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                
                                Text(contact.name.components(separatedBy: " ").first ?? contact.name)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: 60)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}
