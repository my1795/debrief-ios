//
//  InfoButton.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 25/01/2026.
//

import SwiftUI

struct InfoButton: View {
    let topic: EducationTopic
    @Binding var showEducation: Bool

    var body: some View {
        Button {
            showEducation = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
        }
        .sheet(isPresented: $showEducation) {
            EducationSheetView(topic: topic)
        }
    }
}
