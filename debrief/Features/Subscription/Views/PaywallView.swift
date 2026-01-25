//
//  PaywallView.swift
//  debrief
//
//  Subscription paywall/upgrade modal
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PaywallViewModel()
    @ObservedObject private var subscriptionState = SubscriptionState.shared

    /// Optional reason for showing paywall (quota exceeded)
    var reason: QuotaExceededReason?

    /// Callback when purchase is successful
    var onSuccess: (() -> Void)?

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
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView

                        // Plan Cards - All 3 tiers
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(40)
                        } else {
                            allPlansView
                        }

                        // Error Message
                        if let error = viewModel.error {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // CTA Button (only if a paid plan is selected)
                        if viewModel.selectedPackage != nil {
                            ctaButton
                        }

                        // Restore Purchases
                        restoreButton

                        // Legal Links
                        legalLinksView
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: viewModel.purchaseSuccess) { success in
            if success {
                onSuccess?()
                dismiss()
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 12) {
            // Icon based on reason
            Image(systemName: reason != nil ? "exclamationmark.triangle.fill" : "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(reason != nil ? .orange : AppTheme.Colors.accent)

            // Title
            Text(headerTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var headerTitle: String {
        if let reason = reason {
            switch reason {
            case .weeklyDebriefLimit:
                return "Weekly Debrief Limit Reached"
            case .weeklyMinutesLimit:
                return "Weekly Recording Limit Reached"
            case .storageLimit:
                return "Storage Limit Reached"
            default:
                return "Upgrade Your Plan"
            }
        }
        return "Choose Your Plan"
    }

    private var headerSubtitle: String {
        if reason != nil {
            return "Upgrade to continue recording and unlock more features."
        }
        return "Select a plan that fits your needs."
    }

    // MARK: - All Plans View (FREE + PERSONAL + PRO)

    private var allPlansView: some View {
        VStack(spacing: 12) {
            // FREE Plan Card (always shown, not purchasable)
            freePlanCard

            // PERSONAL Plan Card - exact match by product ID
            if let personalPackage = viewModel.packages.first(where: {
                $0.storeProduct.productIdentifier == RevenueCatConstants.ProductIDs.personalMonthly
            }) {
                paidPlanCard(package: personalPackage, tier: .personal)
            }

            // PRO Plan Card - exact match by product ID
            if let proPackage = viewModel.packages.first(where: {
                $0.storeProduct.productIdentifier == RevenueCatConstants.ProductIDs.proMonthly
            }) {
                paidPlanCard(package: proPackage, tier: .pro)
            }

            // Debug: Show if no packages found
            if viewModel.packages.isEmpty && !viewModel.isLoading {
                Text("No subscription packages available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    private var freePlanCard: some View {
        let isCurrentPlan = subscriptionState.currentTier == .free
        let hasSelectedPaidPlan = viewModel.selectedPackage != nil
        let isSelected = isCurrentPlan && !hasSelectedPaidPlan

        return Button {
            // Tapping Free clears the paid plan selection
            viewModel.selectedPackage = nil
        } label: {
            VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "gift.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Free")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if isCurrentPlan {
                            Text("CURRENT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text("Free forever")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Show checkmark if selected (current AND no paid plan selected)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.accent)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

                // Features - dynamically from metadata
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(featuresForTier(.free), id: \.self) { feature in
                        featureRow(feature)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.Colors.selection.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppTheme.Colors.accent.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func paidPlanCard(package: Package, tier: SubscriptionTier) -> some View {
        let isCurrentPlan = subscriptionState.currentTier == tier
        let isSelected = viewModel.selectedPackage?.identifier == package.identifier

        return Button {
            if !isCurrentPlan {
                viewModel.selectPackage(package)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: tier == .pro ? "bolt.circle.fill" : "star.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(tier == .pro ? .orange : AppTheme.Colors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(tier.displayName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            if isCurrentPlan {
                                Text("CURRENT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            if tier == .pro && !isCurrentPlan {
                                Text("BEST VALUE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }

                        Text("\(package.storeProduct.localizedPriceString)/month")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Selection indicator
                    if isCurrentPlan {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.accent)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.accent)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(featuresForTier(tier), id: \.self) { feature in
                        featureRow(feature)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill((isCurrentPlan || isSelected) ? AppTheme.Colors.selection.opacity(0.3) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        (isCurrentPlan || isSelected) ? AppTheme.Colors.accent : Color.white.opacity(0.1),
                        lineWidth: (isCurrentPlan || isSelected) ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCurrentPlan)
        .opacity(isCurrentPlan ? 0.7 : 1.0)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.Colors.accent)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private func featuresForTier(_ tier: SubscriptionTier) -> [String] {
        let meta = viewModel.metadata

        switch tier {
        case .free:
            return [
                "\(meta.freeWeeklyDebriefs) debriefs/week",
                "\(meta.freeWeeklyMinutes) min/week recording",
                "\(meta.freeStorageMB) MB storage"
            ]
        case .personal:
            let debriefs = meta.personalWeeklyDebriefs == -1 ? "Unlimited" : "\(meta.personalWeeklyDebriefs)"
            let minutes = meta.personalWeeklyMinutes == -1 ? "Unlimited" : "\(meta.personalWeeklyMinutes) min/week"
            let storage = meta.personalStorageMB == -1 ? "Unlimited" : "\(meta.personalStorageMB / 1000) GB"
            return [
                "\(debriefs) debriefs",
                "\(minutes) recording",
                "\(storage) storage"
            ]
        case .pro:
            let debriefs = meta.proWeeklyDebriefs == -1 ? "Unlimited" : "\(meta.proWeeklyDebriefs)"
            let minutes = meta.proWeeklyMinutes == -1 ? "Unlimited" : "\(meta.proWeeklyMinutes) min/week"
            let storage = meta.proStorageMB == -1 ? "Unlimited" : "\(meta.proStorageMB / 1000) GB"
            return [
                "\(debriefs) debriefs",
                "\(minutes) recording",
                "\(storage) storage"
            ]
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))

            Text("Unable to load plans")
                .font(.headline)
                .foregroundColor(.white)

            Button("Try Again") {
                Task {
                    await viewModel.loadOfferings()
                }
            }
            .foregroundColor(AppTheme.Colors.accent)
        }
        .padding(40)
    }

    private var ctaButton: some View {
        Button {
            Task {
                await viewModel.purchase()
            }
        } label: {
            HStack {
                if viewModel.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Subscribe Now")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.Colors.primaryButton)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isPurchasing || viewModel.selectedPackage == nil)
    }

    private var restoreButton: some View {
        Button {
            Task {
                await viewModel.restore()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .disabled(viewModel.isLoading)
    }

    private var legalLinksView: some View {
        HStack(spacing: 16) {
            Button("Terms of Service") {
                if let url = AppConfig.shared.termsOfServiceURL {
                    UIApplication.shared.open(url)
                }
            }

            Text("|")

            Button("Privacy Policy") {
                if let url = AppConfig.shared.privacyPolicyURL {
                    UIApplication.shared.open(url)
                }
            }
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.5))
    }
}

// MARK: - Preview

#Preview {
    PaywallView(reason: .weeklyDebriefLimit)
}
