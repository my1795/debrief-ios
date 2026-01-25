//
//  EducationPageView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 25/01/2026.
//

import SwiftUI

struct EducationPageView: View {
    let page: EducationPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(page.emoji)
                .font(.system(size: 64))

            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
