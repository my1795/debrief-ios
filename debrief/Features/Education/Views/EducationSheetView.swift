//
//  EducationSheetView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 25/01/2026.
//

import SwiftUI

struct EducationSheetView: View {
    let topic: EducationTopic
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var educationState = EducationState.shared

    var body: some View {
        ZStack {
            // Background
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

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        educationState.markAsSeen(topic.id)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text(topic.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Page Content with Navigation Arrows
                HStack(spacing: 0) {
                    // Left Arrow
                    Button {
                        withAnimation {
                            if currentPage > 0 {
                                currentPage -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentPage > 0 ? .white : .white.opacity(0.2))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentPage == 0)

                    TabView(selection: $currentPage) {
                        ForEach(Array(topic.pages.enumerated()), id: \.element.id) { index, page in
                            EducationPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Right Arrow
                    Button {
                        withAnimation {
                            if currentPage < topic.pages.count - 1 {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentPage < topic.pages.count - 1 ? .white : .white.opacity(0.2))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentPage == topic.pages.count - 1)
                }

                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<topic.pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 16)

                // CTA Button (only on last page)
                if currentPage == topic.pages.count - 1 {
                    Button {
                        educationState.markAsSeen(topic.id)
                        dismiss()
                    } label: {
                        Text("Got it!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Colors.primaryButton)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    // Skip button for earlier pages
                    Button {
                        withAnimation {
                            currentPage = topic.pages.count - 1
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .modifier(EducationSheetPresentationModifier())
    }
}

// MARK: - iOS 16+ Compatibility

struct EducationSheetPresentationModifier: ViewModifier {
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
