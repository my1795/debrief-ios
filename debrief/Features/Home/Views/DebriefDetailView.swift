//
//  DebriefDetailView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct DebriefDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: DebriefDetailViewModel
    @State private var showDeleteConfirm = false
    @State private var isExporting = false
    @State private var showFullTranscript = false
    
    init(debrief: Debrief, userId: String) {
        _viewModel = StateObject(wrappedValue: DebriefDetailViewModel(debrief: debrief, userId: userId))
    }
    
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
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Status/Error States
                        if viewModel.debrief.status == .failed {
                            statusCard(title: "Processing Failed", message: "We encountered an error while processing this debrief.", color: Color.red)
                        } else if viewModel.debrief.status == .processing {
                            statusCard(title: "Processing Audio...", message: "This usually takes a few minutes.", color: Color.yellow)
                        }
                        
                        // 1. Action Items
                        actionItemsSection
                        
                        // 2. Summary
                        if let summary = viewModel.debrief.summary {
                            detailSection(title: "Summary", content: summary)
                        }
                        
                        // 3. Transcript
                        if let transcript = viewModel.debrief.transcript, !transcript.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Transcript")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(transcript)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineSpacing(4)
                                    .lineLimit(5) // Preview limit
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: { showFullTranscript = true }) {
                                    HStack(spacing: 4) {
                                        Text("Read Full Transcript")
                                            .font(.caption.bold())
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(Color.teal)
                                    .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
                            .onTapGesture {
                                showFullTranscript = true
                            }
                        }
                        
                        // 4. Audio Player
                        audioPlayerSection
                        
                        // Actions
                        actionButtons
                        
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            
            // Loading Overlay
            if viewModel.isDeleting {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Debrief?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.deleteDebrief {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showFullTranscript) {
            if let transcript = viewModel.debrief.transcript {
                TranscriptFullScreenView(transcript: transcript)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Text(viewModel.debrief.contactName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                StatusBadge(status: viewModel.debrief.status)
            }
            
            HStack(spacing: 16) {
                Label(viewModel.debrief.occurredAt.formatted(date: .long, time: .shortened), systemImage: "calendar")
                Label("\(Int(viewModel.debrief.duration / 60)) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private func statusCard(title: String, message: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color.opacity(0.9))
            Text(message)
                .font(.subheadline)
                .foregroundColor(color.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3)))
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Action Items")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if let items = viewModel.debrief.actionItems, !items.isEmpty {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle")
                                .foregroundStyle(Color(hex: "5EEAD4"))
                                .padding(.top, 2)
                            Text(item)
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "checklist")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.2))
                        Text("No action items found")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
    }
    
    private func detailSection(title: String, content: String, font: Font = .body) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            ExpandableText(text: content, font: font)
        }
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
    }
    
    private var audioPlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Recording")
                .font(.headline)
                .foregroundColor(.white)
            
            if let _ = viewModel.debrief.audioUrl {
                HStack(spacing: 16) {
                    Button {
                        viewModel.toggleAudio()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(hex: "2DD4BF"), .white) // teal-400, white
                    }
                    
                    VStack(spacing: 6) {
                        // Fake Waveform
                        HStack(spacing: 3) {
                            ForEach(0..<25) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "5EEAD4").opacity(viewModel.isPlaying ? 0.8 : 0.3))
                                    .frame(height: .random(in: 10...30))
                            }
                        }
                        .frame(height: 32)
                        
                        HStack {
                            Text(viewModel.isPlaying ? "Playing..." : "00:00")
                            Spacer()
                            Text(viewModel.formatDuration(viewModel.debrief.duration))
                        }
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                HStack {
                    Image(systemName: "mic.slash")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Audio recording unavailable")
                        .font(.callout)
                        .italic()
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                isExporting = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "0F766E")) // teal-700
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .sheet(isPresented: $isExporting) {
                ActivityViewController(activityItems: [viewModel.shareableText])
            }
            
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FECACA"))
                    .frame(width: 50)
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}


struct ExpandableText: View {
    let text: String
    let font: Font
    @State private var isExpanded = false
    
    // Config
    private let lineLimit = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(font)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : lineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Only show button if text is long enough (simple heuristic or always show for consistency)
            // For true conditional text, we'd need GeometryReader or TextRenderer, but simple toggle is safer for now.
            // We'll show "Show More" if it's not expanded, "Show Less" if it is.
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption.bold())
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.bold())
                }
                .foregroundStyle(Color.teal) // Using teal theme
                .padding(.top, 4)
            }
        }
    }
}

struct TranscriptFullScreenView: View {
    let transcript: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "134E4A").ignoresSafeArea() // Matching theme background
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Transcript")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white.opacity(0.6), .white.opacity(0.1))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Content
                ScrollView {
                    Text(transcript)
                        .font(.body) // Larger font for reading
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(6)
                        .padding()
                        .textSelection(.enabled) // Allow copying
                }
            }
        }
    }
}
