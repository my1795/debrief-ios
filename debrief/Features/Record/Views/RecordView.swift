//
//  RecordView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RecordViewModel()
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    AppTheme.Colors.backgroundStart,
                    AppTheme.Colors.backgroundMiddle,
                    AppTheme.Colors.backgroundEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Group {
                switch viewModel.state {
                case .recording:
                    recordingView
                case .selectContact:
                    selectContactView
                case .processing, .complete:
                    // Should dismiss immediately, but show minimal loader just in case
                    ProgressView()
                }
            }
        }
    }
    
    // MARK: - Views
    
    var recordingView: some View {
        VStack {
            Spacer()
            
            // Pulsing Recording Animation
            RecordingPulseView()
                .padding(.bottom, 32)
            
            Text("Recording...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(formatTime(Int(viewModel.recordingTime)))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.vertical, 48)
            
            Button {
                viewModel.stopRecording()
            } label: {
                HStack {
                    Image(systemName: "square.fill")
                    Text("Stop Recording")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.white.opacity(0.1))
                .background(Material.ultraThin)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
            }
            
            Spacer()
            
            // Cancel Button
            Button {
                viewModel.discardRecording()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
        }
    }
    
    var selectContactView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Text("Recording Saved!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        viewModel.discardRecording()
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                HStack {
                    Text("Duration:")
                        .foregroundColor(.white.opacity(0.7))
                    Text(formatTime(Int(viewModel.recordingTime)))
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.accent) // teal-300
                }
                .font(.subheadline)
                
                Text("Select a contact for this debrief")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.Colors.accent)
                    TextField("", text: $viewModel.searchQuery, prompt: Text("Search contacts...").foregroundColor(.white.opacity(0.4)))
                        .foregroundColor(.white)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            
            // List
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedContacts, id: \.key) { section in
                        Section(header: 
                            HStack {
                                Text(section.key)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                Spacer()
                            }
                            .background(AppTheme.Colors.listHeader) // Dark header matching theme
                        ) {
                            ForEach(section.value) { contact in
                                Button {
                                    viewModel.selectContact(contact)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(contact.name)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            if let handle = contact.handle {
                                                Text(handle)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        Spacer()
                                        if viewModel.selectedContact?.id == contact.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.Colors.accent)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        viewModel.selectedContact?.id == contact.id ?
                                        AppTheme.Colors.selection.opacity(0.3) :
                                            Color.clear
                                    )
                                    .contentShape(Rectangle()) // Ensure tap target is full row
                                }
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            // Save Button
            if viewModel.selectedContact != nil {
                Button {
                    viewModel.saveDebrief {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save Debrief")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.primaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }
    

    
    func formatTime(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%d:%02d", min, sec)
    }
}
