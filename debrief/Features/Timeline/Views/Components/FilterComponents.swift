//
//  FilterComponents.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 17/01/2026.
//

import SwiftUI
import Combine

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Binding var filters: DebriefFilters
    @Binding var isPresented: Bool
    let onApply: (DebriefFilters) -> Void
    
    // Local state for the sheet before applying
    @State private var tempFilters: DebriefFilters
    
    let allowContactSelection: Bool
    init(filters: Binding<DebriefFilters>, isPresented: Binding<Bool>, allowContactSelection: Bool = true, onApply: @escaping (DebriefFilters) -> Void) {
        self.allowContactSelection = allowContactSelection
        self._filters = filters
        self._isPresented = isPresented
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Section: Contact
                if allowContactSelection {
                    Section(header: Text("Contact")) {
                        NavigationLink(destination: SearchableContactPicker(
                            selectedContactId: $tempFilters.contactId,
                            selectedContactName: $tempFilters.contactName
                        )) {
                            HStack {
                                Text("Person")
                                Spacer()
                                if let name = tempFilters.contactName {
                                    Text(name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Any")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Section: Date Range
                Section(header: Text("Date")) {
                    Picker("Time Period", selection: Binding(
                        get: { tempFilters.dateOption },
                        set: { tempFilters.dateOption = $0 }
                    )) {
                        ForEach(DateRangeOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    
                    if tempFilters.dateOption == .custom {
                        DatePicker("Start Date", selection: $tempFilters.customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $tempFilters.customEndDate, displayedComponents: .date)
                    }
                }
                
                // Section: Clear
                if tempFilters.isActive {
                    Section {
                        Button {
                            tempFilters.clear()
                        } label: {
                            Text("Clear All Filters")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = tempFilters
                        onApply(tempFilters)
                        isPresented = false
                    }
                    .font(.headline)
                }
            }
        }
    }
}

// MARK: - Searchable Contact Picker
struct SearchableContactPicker: View {
    @Binding var selectedContactId: String?
    @Binding var selectedContactName: String?
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = ContactPickerViewModel()
    
    var body: some View {
        List {
            // "Any" option
            Button {
                selectedContactId = nil
                selectedContactName = nil
                dismiss()
            } label: {
                HStack {
                    Text("Any Person")
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedContactId == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(viewModel.filteredContacts) { contact in
                Button {
                    selectedContactId = contact.id
                    selectedContactName = contact.name
                    dismiss()
                } label: {
                    HStack {
                        ContactAvatar(name: contact.name, size: 32)
                        Text(contact.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedContactId == contact.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Select Person")
        .task {
            await viewModel.loadContacts()
        }
    }
}

// Simple ViewModel for the picker
class ContactPickerViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadContacts() async {
        do {
            let fetched = try await ContactStoreService.shared.fetchContacts()
            await MainActor.run {
                self.contacts = fetched
            }
        } catch {
            Logger.error("Failed to fetch contacts: \(error)")
        }
    }
}

// MARK: - Active Filter Chips
struct ActiveFilterChips: View {
    @Binding var filters: DebriefFilters
    let onUpdate: (DebriefFilters) -> Void
    
    private var dateLabel: String {
        if filters.dateOption == .custom {
             let formatter = DateFormatter()
             formatter.dateFormat = "MMM d"
             return "\(formatter.string(from: filters.customStartDate)) - \(formatter.string(from: filters.customEndDate))"
        } else {
            return filters.dateOption.displayName
        }
    }
    
    var body: some View {
        if filters.isActive {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let name = filters.contactName {
                        FilterChip(label: name, icon: "person.fill") {
                            var new = filters
                            new.contactId = nil
                            new.contactName = nil
                            onUpdate(new)
                        }
                    }
                    
                    if filters.dateOption != .all {
                        FilterChip(label: dateLabel, icon: "calendar") {
                            var new = filters
                            new.dateOption = .all
                            onUpdate(new)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(hex: "022c22")) // Match bg
        }
    }
}

struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}

// Helper for Avatar
struct ContactAvatar: View {
    let name: String
    let size: CGFloat
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.primary)
            )
    }
}
