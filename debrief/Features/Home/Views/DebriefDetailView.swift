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
    
    // Action Items Selection
    @State private var selectedActionItemIndices: Set<Int> = []
    @State private var showReminderSheet = false
    
    // Action Item Editing
    @State private var editingActionItemIndex: Int? = nil
    @State private var showAddActionItem = false
    
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
                    .padding(.bottom, 100) // Extra padding to clear tab bar with record button
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
        .sheet(isPresented: $showReminderSheet) {
            ReminderDatePickerSheet(
                selectedItems: selectedActionItems,
                contactName: viewModel.debrief.contactName,
                onDismiss: {
                    showReminderSheet = false
                },
                onConfirm: { _ in
                    showReminderSheet = false
                    // Clear selection after creating reminders
                    withAnimation(.spring(response: 0.3)) {
                        selectedActionItemIndices.removeAll()
                    }
                }
            )
            .modifier(LargeSheetModifier())
        }
        .sheet(isPresented: $showAddActionItem) {
            AddActionItemSheet(
                onSave: { text in
                    viewModel.addActionItem(text)
                }
            )
            .modifier(MediumSheetModifier())
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
    
    // Computed property for selected action item texts
    private var selectedActionItems: [String] {
        guard let items = viewModel.debrief.actionItems else { return [] }
        return selectedActionItemIndices.sorted().compactMap { index in
            index < items.count ? items[index] : nil
        }
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Action Items")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                // Selection hint
                if let items = viewModel.debrief.actionItems, !items.isEmpty {
                    if selectedActionItemIndices.isEmpty {
                        Text("Tap to select")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedActionItemIndices.removeAll()
                            }
                        } label: {
                            Text("Clear")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color(hex: "5EEAD4"))
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let items = viewModel.debrief.actionItems, !items.isEmpty {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        SwipeableActionItemRow(
                            item: item,
                            isSelected: selectedActionItemIndices.contains(index),
                            isEditing: editingActionItemIndex == index,
                            onCheckboxTap: {
                                // Cancel any editing first
                                if editingActionItemIndex != nil {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        editingActionItemIndex = nil
                                    }
                                }
                                
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    if selectedActionItemIndices.contains(index) {
                                        selectedActionItemIndices.remove(index)
                                    } else {
                                        selectedActionItemIndices.insert(index)
                                    }
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            },
                            onTextTap: {
                                // Tap on text to edit
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    editingActionItemIndex = index
                                }
                            },
                            onEdit: { newText in
                                viewModel.editActionItem(at: index, newText: newText)
                                withAnimation(.easeOut(duration: 0.2)) {
                                    editingActionItemIndex = nil
                                }
                            },
                            onDelete: {
                                viewModel.deleteActionItem(at: index)
                                selectedActionItemIndices.remove(index)
                                withAnimation(.easeOut(duration: 0.2)) {
                                    editingActionItemIndex = nil
                                }
                            },
                            onCancelEdit: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    editingActionItemIndex = nil
                                }
                            }
                        )
                    }
                    
                    // Add new action item button (max 5 items)
                    if items.count < 5 {
                        Button {
                            showAddActionItem = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Action Item")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "5EEAD4"))
                            .padding(.vertical, 6)
                        }
                    }
                } else {
                    // Empty state with add button
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checklist")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.2))
                            Text("No action items")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Button {
                            showAddActionItem = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Action Item")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "5EEAD4"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            
            // Inline Reminder Button (appears when items selected)
            if !selectedActionItemIndices.isEmpty {
                Button {
                    showReminderSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Set Reminder for \(selectedActionItemIndices.count) \(selectedActionItemIndices.count == 1 ? "Item" : "Items")")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "14B8A6"), Color(hex: "0D9488")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedActionItemIndices.count)
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
                    // Play/Pause/Loading Button
                    Button {
                        viewModel.toggleAudio()
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                // Loading spinner
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "2DD4BF")))
                                    .scaleEffect(1.5)
                                    .frame(width: 48, height: 48)
                            } else {
                                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 48))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color(hex: "2DD4BF"), .white)
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    VStack(spacing: 6) {
                        // Animated Waveform
                        AnimatedWaveformView(
                            isPlaying: viewModel.isPlaying,
                            isLoading: viewModel.isLoading
                        )
                        .frame(height: 32)
                        
                        HStack {
                            Text(audioStatusText)
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
    
    private var audioStatusText: String {
        if viewModel.isLoading {
            return "Loading..."
        } else if viewModel.isPlaying {
            return "Playing..."
        } else {
            return "00:00"
        }
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
                    .frame(height: 50)
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
                    .frame(width: 56, height: 50)
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Selectable Action Item Row

struct SelectableActionItemRow: View {
    let item: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Selection Circle
                ZStack {
                    Circle()
                        .stroke(Color(hex: "5EEAD4"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "5EEAD4"))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "134E4A"))
                    }
                }
                .padding(.top, 2)
                
                // Item Text
                Text(item)
                    .foregroundColor(.white.opacity(isSelected ? 1.0 : 0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "5EEAD4").opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "5EEAD4").opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheet Modifier for iOS 15 Compatibility

struct LargeSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
        } else {
            content
        }
    }
}

struct MediumSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

// MARK: - Swipeable Action Item Row

struct SwipeableActionItemRow: View {
    let item: String
    let isSelected: Bool
    let isEditing: Bool
    let onCheckboxTap: () -> Void
    let onTextTap: () -> Void
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    let onCancelEdit: () -> Void
    
    @State private var editText: String = ""
    @State private var offset: CGFloat = 0
    @State private var showDeleteButton: Bool = false
    @FocusState private var isFocused: Bool
    
    private let deleteButtonWidth: CGFloat = 70
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button (revealed by swipe)
            if showDeleteButton {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        onDelete()
                        resetSwipe()
                    }
                } label: {
                    VStack {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                        Text("Delete")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth - 8)
                    .frame(maxHeight: .infinity)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Main content
            mainContent
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isEditing {
                                let translation = value.translation.width
                                if translation < 0 {
                                    offset = max(translation, -deleteButtonWidth)
                                } else if showDeleteButton {
                                    offset = min(0, -deleteButtonWidth + translation)
                                }
                            }
                        }
                        .onEnded { value in
                            if !isEditing {
                                withAnimation(.spring(response: 0.3)) {
                                    if value.translation.width < -deleteButtonWidth / 2 {
                                        offset = -deleteButtonWidth
                                        showDeleteButton = true
                                    } else {
                                        resetSwipe()
                                    }
                                }
                            }
                        }
                )
        }
        .animation(.spring(response: 0.3), value: showDeleteButton)
    }
    
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox (tap to select for reminder)
            Button(action: {
                resetSwipe()
                onCheckboxTap()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "5EEAD4"), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "5EEAD4"))
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "134E4A"))
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            // Text content or edit field
            if isEditing {
                editingView
            } else {
                // Tappable text to edit
                Text(item)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        resetSwipe()
                        onTextTap()
                    }
                
                // Edit pencil icon hint
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isEditing ? Color(hex: "5EEAD4").opacity(0.08) : 
                      (isSelected ? Color(hex: "5EEAD4").opacity(0.12) : Color.white.opacity(0.04)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isEditing ? Color(hex: "5EEAD4").opacity(0.4) : 
                        (isSelected ? Color(hex: "5EEAD4").opacity(0.25) : Color.white.opacity(0.06)), lineWidth: 1)
        )
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if #available(iOS 16.0, *) {
                TextField("", text: $editText, axis: .vertical)
                    .foregroundColor(.white)
                    .font(.body)
                    .focused($isFocused)
                    .lineLimit(2...5)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "5EEAD4").opacity(0.4), lineWidth: 1)
                    )
            } else {
                // iOS 15 fallback: Use TextEditor for multiline editing
                TextEditor(text: $editText)
                    .foregroundColor(.white)
                    .font(.body)
                    .focused($isFocused)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "5EEAD4").opacity(0.4), lineWidth: 1)
                    )
            }
            
            HStack(spacing: 10) {
                // Save button
                Button {
                    if !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onEdit(editText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                        Text("Save")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(Color(hex: "134E4A"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "5EEAD4"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                
                // Cancel button
                Button {
                    onCancelEdit()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Delete button (visible in edit mode)
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "FCA5A5"))
                        .padding(10)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            editText = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    private func resetSwipe() {
        withAnimation(.spring(response: 0.3)) {
            offset = 0
            showDeleteButton = false
        }
    }
}

