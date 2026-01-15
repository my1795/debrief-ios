//
//  StatsSummaryView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 14/01/2026.
//

import SwiftUI

struct StatsSummaryView: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            if viewModel.isLoading && viewModel.stats.isEmpty {
                 ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if let error = viewModel.errorMessage, viewModel.stats.isEmpty {
                 Text(error)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                 ForEach(viewModel.stats) { stat in
                     VStack(spacing: 4) {
                         // Title
                         Text(stat.title.uppercased())
                             .font(.system(size: 10, weight: .bold))
                             .foregroundStyle(.white.opacity(0.5))
                         
                         // Value
                         HStack(spacing: 4) {
                             Image(systemName: stat.icon)
                                 .font(.system(size: 12))
                                 .foregroundStyle(Color(hex: "2DD4BF")) // teal-400
                             
                             Text(stat.value)
                                 .font(.system(size: 16, weight: .bold))
                                 .foregroundStyle(.white)
                         }
                         
                         // Trend
                         if let subValue = stat.subValue {
                             Text(subValue)
                                 .font(.system(size: 10, weight: .medium))
                                 .foregroundStyle(trendColor(isPositive: stat.isPositive))
                         }
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 12)
                     .background(Material.ultraThin)
                     .background(Color.black.opacity(0.2))
                     .clipShape(RoundedRectangle(cornerRadius: 12))
                     .overlay(
                         RoundedRectangle(cornerRadius: 12)
                             .stroke(.white.opacity(0.1), lineWidth: 1)
                     )
                 }
            }
        }
    }
    
    private func trendColor(isPositive: Bool?) -> Color {
        guard let isPositive = isPositive else { return .white.opacity(0.5) }
        return isPositive ? Color(hex: "34D399") : Color(hex: "F87171") // emerald-400 vs red-400
    }
}
