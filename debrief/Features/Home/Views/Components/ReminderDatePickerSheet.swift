//
//  ReminderDatePickerSheet.swift
//  debrief
//
//  Bottom sheet for selecting reminder date
//

import SwiftUI

struct ReminderDatePickerSheet: View {
    let selectedItems: [String]
    let contactName: String
    let onDismiss: () -> Void
    let onConfirm: (Date?) -> Void
    
    @State private var selectedDate: Date = Date()
    @State private var useCustomDate = false
    @State private var isCreating = false
    
    enum QuickOption: String, CaseIterable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case nextWeek = "Next Week"
        
        var date: Date {
            let calendar = Calendar.current
            switch self {
            case .today:
                // Set to 9 AM today or now if past 9 AM
                let now = Date()
                let nineAM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
                return nineAM > now ? nineAM : now.addingTimeInterval(3600) // 1 hour from now
            case .tomorrow:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            case .nextWeek:
                let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: nextWeek) ?? nextWeek
            }
        }
        
        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .tomorrow: return "sunrise.fill"
            case .nextWeek: return "calendar"
            }
        }
    }
    
    @State private var selectedQuickOption: QuickOption? = .tomorrow
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "134E4A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header - Selected Items
                        VStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(hex: "5EEAD4"))
                            
                            Text("\(selectedItems.count) \(selectedItems.count == 1 ? "item" : "items") selected")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(.top)
                        
                        // Selected Items Preview (scrollable if many)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedItems.prefix(5), id: \.self) { item in
                                    Text(item)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                if selectedItems.count > 5 {
                                    Text("+\(selectedItems.count - 5) more")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .background(.white.opacity(0.2))
                            .padding(.horizontal)
                        
                        // Quick Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When to remind?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                ForEach(QuickOption.allCases, id: \.self) { option in
                                    QuickOptionButton(
                                        option: option,
                                        isSelected: selectedQuickOption == option && !useCustomDate,
                                        action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedQuickOption = option
                                                useCustomDate = false
                                                selectedDate = option.date
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Custom Date
                        VStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    useCustomDate.toggle()
                                    if useCustomDate {
                                        selectedQuickOption = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                    Text("Custom Date & Time")
                                    Spacer()
                                    Image(systemName: useCustomDate ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(useCustomDate ? Color(hex: "5EEAD4") : .white.opacity(0.7))
                                .padding()
                                .background(useCustomDate ? Color.white.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            
                            if useCustomDate {
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color(hex: "14B8A6"))
                                .colorScheme(.light)
                                .frame(minHeight: 350)
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Selected Date Summary
                        VStack(spacing: 4) {
                            Text("Reminder set for:")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Text(formattedSelectedDate)
                                .font(.headline)
                                .foregroundStyle(Color(hex: "5EEAD4"))
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 80) // Space for fixed button
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Fixed Confirm Button
                Button {
                    createReminders()
                } label: {
                    HStack(spacing: 8) {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                            Text("Create \(selectedItems.count == 1 ? "Reminder" : "Reminders")")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "14B8A6"), Color(hex: "0D9488")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "14B8A6").opacity(0.3), radius: 8, y: 4)
                }
                .disabled(isCreating)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(hex: "134E4A"))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
    
    // Computed property to format the selected date
    private var formattedSelectedDate: String {
        let date = useCustomDate ? selectedDate : (selectedQuickOption?.date ?? Date())
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func createReminders() {
        isCreating = true
        
        let dueDate = useCustomDate ? selectedDate : (selectedQuickOption?.date ?? Date())
        
        Task {
            let count = await ReminderService.shared.createReminders(
                items: selectedItems,
                dueDate: dueDate,
                contactName: contactName
            )
            
            await MainActor.run {
                isCreating = false
                if count > 0 {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                onConfirm(dueDate)
            }
        }
    }
}

// MARK: - Quick Option Button

private struct QuickOptionButton: View {
    let option: ReminderDatePickerSheet.QuickOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.icon)
                    .font(.title3)
                Text(option.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? Color(hex: "134E4A") : .white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? Color(hex: "5EEAD4")
                    : Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReminderDatePickerSheet(
        selectedItems: ["Test the code base", "Do a production build tomorrow"],
        contactName: "Abdullah Orion",
        onDismiss: {},
        onConfirm: { _ in }
    )
}
