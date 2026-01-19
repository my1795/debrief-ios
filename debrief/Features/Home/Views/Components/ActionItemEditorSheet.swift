//
//  AddActionItemSheet.swift
//  debrief
//
//  Compact sheet for adding new action items
//

import SwiftUI

struct AddActionItemSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let onSave: (String) -> Void
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Add Action Item")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Add") {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(canSave ? Color(hex: "2DD4BF") : .gray)
                .disabled(!canSave)
            }
            .padding()
            .background(Color(hex: "115E59"))
            
            // Text Input
            VStack(alignment: .leading, spacing: 12) {
                if #available(iOS 16.0, *) {
                    TextField("What needs to be done?", text: $text, axis: .vertical)
                        .foregroundColor(.white)
                        .font(.body)
                        .focused($isFocused)
                        .lineLimit(2)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "5EEAD4").opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: text) { newValue in
                            if newValue.count > 200 {
                                text = String(newValue.prefix(200))
                            }
                        }
                } else {
                    // Fallback for iOS < 16: no axis or ranged lineLimit support
                    TextField("What needs to be done?", text: $text)
                        .foregroundColor(.white)
                        .font(.body)
                        .focused($isFocused)
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "5EEAD4").opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: text) { newValue in
                            if newValue.count > 200 {
                                text = String(newValue.prefix(200))
                            }
                        }
                }
                
                HStack {
                    Text("Add tasks, follow-ups, or reminders from your debrief.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    Text("\(text.count)/200")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(text.count >= 200 ? .red : .white.opacity(0.4))
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(hex: "134E4A").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
    
    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AddActionItemSheet(onSave: { _ in })
}
