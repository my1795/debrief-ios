//
//  SearchView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 19/01/2026.
//

import SwiftUI
import FirebaseAuth

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showInfoSheet = false
    
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.Colors.purple)
                    Text("AI Semantic Search")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Button {
                        showInfoSheet = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.leading, 4)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.purple)
                }
                .padding()
                .background(AppTheme.Colors.background)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Search debriefs by meaning...", text: $viewModel.searchText)
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
                
                // Results
                if viewModel.isLoading {
                    SearchLoadingView()
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    NoResultsView()
                } else if viewModel.searchResults.isEmpty {
                    EmptySearchView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { debrief in
                                NavigationLink(destination: DebriefDetailView(debrief: debrief, userId: userId)) {
                                    DebriefItem(debrief: debrief, showContactName: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showInfoSheet) {
                SearchInfoSheet()
            }
        }
    }
}

// MARK: - Loading Animation View

struct SearchLoadingView: View {
    @State private var currentMessageIndex = 0
    @State private var isPulsing = false
    
    private let messages = [
        "Analyzing your query...",
        "Understanding meaning...",
        "Finding connections...",
        "Scanning insights...",
        "Matching debriefs..."
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Pulsing sparkle animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(AppTheme.Colors.purple.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0.3 : 0.6)
                
                // Inner glow
                Circle()
                    .fill(AppTheme.Colors.purple.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                
                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.Colors.purple)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
            }
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
            
            // Cycling message
            Text(messages[currentMessageIndex])
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .animation(.easeInOut, value: currentMessageIndex)
            
            Spacer()
        }
        .onAppear {
            startMessageCycle()
        }
    }
    
    private func startMessageCycle() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

// MARK: - Empty States

struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text("No results found")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text("Try describing the conversation differently")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
        Spacer()
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.purple)
            Text("Search by meaning")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Type a phrase like 'meeting about finances' to find related debriefs")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
        Spacer()
    }
}

// MARK: - Info Sheet

struct SearchInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.purple)
                Text("About Semantic Search")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Description
            Text("Debrief uses AI to understand the **meaning** of your search, not just matching keywords.")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Examples Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Examples")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                ExampleRow(query: "money", finds: "budget, pricing, finances, costs")
                ExampleRow(query: "meeting next week", finds: "calls about scheduling, follow-ups")
                ExampleRow(query: "project update", finds: "status reports, progress discussions")
                ExampleRow(query: "travel plans", finds: "trips, flights, hotel bookings")
            }
            .padding()
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(12)
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Tips")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("• Use natural language, like asking a question")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("• Describe what the conversation was about")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("• Try different phrasings if no results found")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(24)
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }
}

struct ExampleRow: View {
    let query: String
    let finds: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("→")
                .foregroundColor(AppTheme.Colors.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("'\(query)'")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("finds: \(finds)")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}
