//
//  DebriefDetailView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct DebriefDetailView: View {
    let debrief: Debrief
    @Environment(\.dismiss) var dismiss
    @State private var isPlaying = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: "134E4A"), // teal-900
                    Color(hex: "115E59"), // teal-800
                    Color(hex: "064E3B")  // emerald-900
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Text(debrief.contactName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    StatusBadge(status: debrief.status)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Meta Info
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(debrief.occurredAt.formatted(date: .long, time: .shortened))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(Int(debrief.duration / 60)) min")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 60) // Align with title text roughly
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Failed State
                        if debrief.status == .failed {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Processing Failed")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "FEE2E2")) // red-100
                                Text("We encountered an error while processing this debrief. Please try again.")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "FECACA")) // red-200
                                
                                Button {
                                    // Retry action
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Retry Processing")
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.red)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                        }
                        
                        // Processing State
                        if debrief.status == .processing {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Processing Audio...")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "FEF9C3")) // yellow-100
                                Text("Your debrief is being processed. This usually takes a few minutes.")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "FEF08A")) // yellow-200
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3)))
                        }
                        
                        // Summary
                        if let summary = debrief.summary {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Summary")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(summary)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(.white.opacity(0.1))
                            .background(Material.ultraThin)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))
                        }
                        
                        // Action Items
                        if let items = debrief.actionItems, !items.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Action Items")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(items, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("•")
                                                .font(.headline)
                                                .foregroundColor(Color(hex: "5EEAD4")) // teal-300
                                            Text(item)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.white.opacity(0.1))
                            .background(Material.ultraThin)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))
                        }
                        
                        // Audio Player Placeholder
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Audio Recording")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                Button {
                                    isPlaying.toggle()
                                } label: {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color(hex: "14B8A6")) // teal-500
                                        .clipShape(Circle())
                                }
                                
                                VStack(spacing: 4) {
                                    Capsule()
                                        .fill(.white.opacity(0.2))
                                        .frame(height: 8)
                                        .overlay(
                                            GeometryReader { geo in
                                                Capsule()
                                                    .fill(Color(hex: "2DD4BF")) // teal-400
                                                    .frame(width: geo.size.width * 0.33)
                                            }
                                        )
                                    
                                    HStack {
                                        Text("1:23")
                                        Spacer()
                                        Text("\(Int(debrief.duration / 60)) min")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .background(.white.opacity(0.1))
                        .background(Material.ultraThin)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))
                        
                        // Actions buttons
                        HStack(spacing: 12) {
                            Button {
                                // Export
                            } label: {
                                HBase {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "14B8A6")) // teal-500
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "FECACA")) // red-200
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                            }
                        }
                        .padding(.bottom, 32)
                        
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Debrief?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                dismiss() // Logic would go here
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. The debrief and its audio will be permanently deleted.")
        }
    }
}

// Helper for convenient HStack styling
struct HBase<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack(spacing: 8) {
            content
        }
    }
}
