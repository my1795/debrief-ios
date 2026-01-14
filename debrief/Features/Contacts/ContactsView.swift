//
//  ContactsView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI

struct ContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "134E4A") // Deep Teal Background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Contacts")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.6))
                        TextField("Search contacts...", text: $viewModel.searchText)
                            .foregroundStyle(.white)
                            .tint(.white) // Cursor color
                            .onChange(of: viewModel.searchText) { _ in
                                viewModel.filterContacts()
                            }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.2)) // Darker, more neutral background
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if viewModel.contacts.isEmpty {
                        if let error = viewModel.errorMessage {
                            ContentUnavailableView("Access Needed", systemImage: "lock.fill", description: Text(error))
                                .foregroundStyle(.white)
                        } else {
                            ContentUnavailableView("No Contacts", systemImage: "person.2.slash", description: Text("No contacts found."))
                                .foregroundStyle(.white)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.contacts) { contact in
                                    NavigationLink(destination: ContactDetailView(contact: contact)) {
                                        ContactRow(contact: contact)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadContacts()
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar Placeholder
            Circle()
                .fill(Color(hex: "2DD4BF")) // Teal-400
                .frame(width: 44, height: 44)
                .overlay(
                    Text(getInitials(name: contact.name))
                        .font(.headline)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let handle = contact.handle {
                    Text(handle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    func getInitials(name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "?" }
        let first = parts[0].prefix(1)
        let last = parts.count > 1 ? parts[1].prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
