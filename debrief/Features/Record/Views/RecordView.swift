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
                    Color(hex: "134E4A"), // teal-900
                    Color(hex: "115E59"), // teal-800
                    Color(hex: "064E3B")  // emerald-900
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
                case .processing:
                    processingView
                case .complete:
                    completeView
                }
            }
        }
    }
    
    // MARK: - Views
    
    var recordingView: some View {
        VStack {
            Spacer()
            
            // Pulse Animation Placeholder
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 20)
                            .scaleEffect(1.1)
                            .opacity(0.5)
                    )
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 32)
            
            Text("Recording...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(formatTime(viewModel.recordingTime))
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
        }
    }
    
    var selectContactView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Recording Saved!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Duration:")
                        .foregroundColor(.white.opacity(0.7))
                    Text(formatTime(viewModel.recordingTime))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "5EEAD4")) // teal-300
                }
                .font(.subheadline)
                
                Text("Select a contact for this debrief")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "5EEAD4"))
                    TextField("", text: $viewModel.searchQuery, prompt: Text("Search contacts...").foregroundColor(.white.opacity(0.4)))
                        .foregroundColor(.white)
                        .onChange(of: viewModel.searchQuery) { _ in
                            viewModel.filterContacts()
                        }
                }
                .padding(12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            
            // List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredContacts) { contact in
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
                                        .foregroundColor(Color(hex: "5EEAD4"))
                                }
                            }
                            .padding()
                            .background(
                                viewModel.selectedContact?.id == contact.id ?
                                Color(hex: "2DD4BF").opacity(0.3) :
                                    Color.white.opacity(0.1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button {
                        viewModel.isNewContactFormVisible = true
                    } label: {
                        Text("+ Create New Contact")
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [5])).foregroundColor(.white.opacity(0.3)))
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            
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
                    .background(Color(hex: "14B8A6")) // teal-500
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.isNewContactFormVisible) {
            // Simple New Contact Form
            ZStack {
                Color(hex: "115E59").ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("New Contact")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    TextField("Name", text: $viewModel.newContactName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Company (Optional)", text: $viewModel.newContactHandle)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button("Cancel") { viewModel.isNewContactFormVisible = false }
                            .foregroundColor(.white)
                        Spacer()
                        Button("Create") { viewModel.createContact() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "14B8A6"))
                    }
                }
                .padding()
            }
            .presentationDetents([.height(300)])
        }
    }
    
    var processingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(2)
                .tint(Color(hex: "5EEAD4"))
                .padding(.bottom, 24)
            
            Text("Processing...")
                .font(.title2)
                .foregroundColor(.white)
            Text("Uploading and processing your debrief")
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    var completeView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.green)
                .padding(.bottom, 24)
            
            Text("Complete!")
                .font(.title2)
                .foregroundColor(.white)
            Text("Your debrief has been saved")
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%d:%02d", min, sec)
    }
}
