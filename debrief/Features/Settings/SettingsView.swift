//
//  SettingsView.swift
//  debrief
//
//  Created by Mustafa Yıldırım on 13/01/2026.
//

import SwiftUI
import RevenueCat

struct SettingsView: View {
    @ObservedObject var authSession: AuthSession
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var subscriptionState = SubscriptionState.shared
    @State private var showPaywall = false
    @State private var showSubscriptionWarningBeforeDelete = false
    @State private var isRestoringPurchases = false
    @State private var restoreAlert: RestoreAlertType?

    enum RestoreAlertType: Identifiable {
        case success
        case noPurchases
        case error(String)

        var id: String {
            switch self {
            case .success: return "success"
            case .noPurchases: return "noPurchases"
            case .error: return "error"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "134E4A"), // teal-900
                        Color(hex: "115E59"), // teal-800
                        Color(hex: "064E3B")  // emerald-900
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Title
                        HStack {
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Privacy First Banner
                        PrivacyBanner()
                            .padding(.horizontal)
                        
                        // Account Section
                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "person.circle.fill", title: "Profile", value: authSession.user?.email ?? "User")
                        }
                        
                        // Sign Out Section (Separate Container)
                        SettingsSection(title: "") {
                            Button(action: {
                                authSession.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Sign Out")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.red.opacity(0.8)) // Softer Red
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.vertical, -8) // Tighten layout within section if needed, or just let it be
                        }
                        
                        // Plan Section
                        SettingsSection(title: "Plan") {
                            // Current Plan Display
                            HStack(spacing: 12) {
                                Image(systemName: planIcon)
                                    .font(.system(size: 20))
                                    .frame(width: 24)
                                    .foregroundStyle(planIconColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Current Plan")
                                        .foregroundStyle(.white)
                                    if subscriptionState.isSubscribed, let expiresAt = subscriptionState.expiresAt {
                                        if subscriptionState.willRenew {
                                            Text("Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.5))
                                        } else {
                                            Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundStyle(.orange.opacity(0.8))
                                        }
                                    }
                                }

                                Spacer()

                                Text(subscriptionState.currentTier.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(planIconColor)
                            }
                            .padding(.vertical, 12)

                            // Upgrade Button (FREE tier only)
                            if subscriptionState.currentTier == .free {
                                Button {
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.accent)
                                        Text("Upgrade")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 12)
                            }

                            // Upgrade to Pro (PERSONAL tier)
                            if subscriptionState.currentTier == .personal {
                                Button {
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Image(systemName: "bolt.circle.fill")
                                            .foregroundStyle(.orange)
                                        Text("Upgrade to Pro")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 12)
                            }

                            // Restore Purchases (FREE and PERSONAL only)
                            if subscriptionState.currentTier != .pro {
                                Button {
                                    Task {
                                        await restorePurchases()
                                    }
                                } label: {
                                    HStack {
                                        if isRestoringPurchases {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                                .foregroundStyle(Color(hex: "94A3B8"))
                                        }
                                        Text("Restore Purchases")
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                }
                                .disabled(isRestoringPurchases)
                                .padding(.vertical, 12)
                            }

                            // Manage Subscription (subscribed users only)
                            if subscriptionState.isSubscribed {
                                Button {
                                    openSubscriptionManagement()
                                } label: {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(Color(hex: "2DD4BF"))
                                        Text("Manage Subscription")
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 12)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            ToggleRow(icon: "bell.fill", title: "Notifications", isOn: $viewModel.notificationsEnabled)
                        }
                        
                        // Privacy & Support Section
                        SettingsSection(title: "Privacy & Support") {
                            Button {
                                viewModel.openPrivacyPolicy()
                            } label: {
                                SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", showChevron: true)
                            }

                            Button {
                                viewModel.openDataHandling()
                            } label: {
                                SettingsRow(icon: "lock.shield.fill", title: "Data Handling", value: "More Info", showChevron: true)
                            }

                            Button {
                                viewModel.openHelpCenter()
                            } label: {
                                SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", showChevron: true)
                            }
                        }
                        
                        // Storage Section
                        SettingsSection(title: "Storage") {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "internaldrive.fill")
                                        .foregroundStyle(Color.teal)
                                    Text("Storage Used")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if viewModel.isClearingVoiceData {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("\(viewModel.storageUsedMB) MB")
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }

                                Button(action: {
                                    viewModel.showClearConfirmation = true
                                }) {
                                    HStack {
                                        if viewModel.isClearingVoiceData {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FECACA")))
                                                .scaleEffect(0.7)
                                            Text("Freeing Space...")
                                        } else {
                                            Text("Free Voice Space")
                                        }
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(viewModel.canFreeSpace ? Color(hex: "FECACA") : Color.gray.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.canFreeSpace ? Color.white.opacity(0.05) : Color.white.opacity(0.02)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .disabled(!viewModel.canFreeSpace || viewModel.isClearingVoiceData)
                                .alert(isPresented: $viewModel.showClearConfirmation) {
                                    Alert(
                                        title: Text("Free Voice Space?"),
                                        message: Text("This will delete all voice recordings (\(viewModel.storageUsedMB) MB) from your device and cloud.\n\n✅ Your transcripts, summaries, and action items will be preserved."),
                                        primaryButton: .destructive(Text("Delete Voice Files")) {
                                            viewModel.clearVoiceData()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // App Version
                        Text("Debrief AI \(viewModel.appVersion)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.top, 8)
                        
                        // Danger Zone (Delete Account Only)
                        SettingsSection(title: "Danger Zone") {
                            Button(action: {
                                // Check if user has active subscription first
                                if subscriptionState.isSubscribed {
                                    showSubscriptionWarningBeforeDelete = true
                                } else {
                                    viewModel.showDeleteAccountWarning = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.orange) // Orange Icon
                                    Text("Delete Account")
                                        .foregroundStyle(Color.orange) // Orange Text
                                }
                                .font(.headline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange.opacity(0.1)) // Very light orange/reddish bg
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.bottom, 100) // Extra padding for scrolling
                    }
                    .padding(.bottom, 20)
                }
            }
            // Warning Sheet
            .sheet(isPresented: $viewModel.showDeleteAccountWarning) {
                ZStack {
                    Color(hex: "1F2937").ignoresSafeArea() // Dark gray bg
                    
                    VStack(spacing: 24) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.red)
                        
                        Text("Delete Account?")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("⚠️ This action will permanently delete:")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            BulletPoint(text: "All your recordings & audio files")
                            BulletPoint(text: "All transcripts and summaries")
                            BulletPoint(text: "Your call history")
                            BulletPoint(text: "Usage statistics")
                            BulletPoint(text: "Your account login")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("This action cannot be undone.\nYour data cannot be recovered.")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showDeleteAccountWarning = false
                            // Delay slightly to allow sheet to close before showing alert/input if needed
                            // Or better, transition to next "screen" within sheet if complex. 
                            // User asked for "Screen 3: Final Confirmation". Let's toggle the next state.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.showDeleteConfirmationInput = true
                            }
                        }) {
                            Text("I Understand, Continue")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button("Cancel") {
                            viewModel.showDeleteAccountWarning = false
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(24)
                }
                .modifier(PresentationDetentsModifier())
            }
            // Final Confirmation Input
            .alert("Final Confirmation", isPresented: $viewModel.showDeleteConfirmationInput) {
                TextField("Type DELETE", text: $viewModel.deleteConfirmationText)
                Button("Permanently Delete", role: .destructive) {
                    viewModel.deleteAccount()
                }
                .disabled(viewModel.deleteConfirmationText != "DELETE")
                
                Button("Cancel", role: .cancel) {
                    viewModel.deleteConfirmationText = ""
                }
            } message: {
                Text("Please type \"DELETE\" to confirm permanent account deletion.")
            }
            // Loading Overlay
            .overlay {
                if viewModel.isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        ProgressView("Deleting Account...")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }
                }
            }
            // Paywall Sheet
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            // Subscription Warning Before Delete
            .sheet(isPresented: $showSubscriptionWarningBeforeDelete) {
                subscriptionWarningSheet
            }
            // Refresh subscription status in background when Settings appears
            .task(priority: .background) {
                do {
                    try await SubscriptionService.shared.refreshSubscriptionStatus()
                } catch {
                    // Silent fail - don't bother user with refresh errors
                    Logger.debug("Background subscription refresh failed: \(error)")
                }
            }
            // Restore Purchases Alert
            .alert(item: $restoreAlert) { alertType in
                switch alertType {
                case .success:
                    return Alert(
                        title: Text("Purchases Restored"),
                        message: Text("Your \(subscriptionState.currentTier.displayName) subscription has been restored."),
                        dismissButton: .default(Text("OK"))
                    )
                case .noPurchases:
                    return Alert(
                        title: Text("No Purchases Found"),
                        message: Text("We couldn't find any previous purchases for this Apple ID."),
                        dismissButton: .default(Text("OK"))
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Restore Failed"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private var planIcon: String {
        switch subscriptionState.currentTier {
        case .free: return "star.circle"
        case .personal: return "star.circle.fill"
        case .pro: return "bolt.circle.fill"
        }
    }

    private var planIconColor: Color {
        switch subscriptionState.currentTier {
        case .free: return Color(hex: "2DD4BF") // teal-400
        case .personal: return Color(hex: "2DD4BF") // teal-400
        case .pro: return .orange
        }
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let customerInfo = try await SubscriptionService.shared.restorePurchases()

            if customerInfo.entitlements.active.isEmpty {
                restoreAlert = .noPurchases
            } else {
                restoreAlert = .success
            }
        } catch {
            restoreAlert = .error(error.localizedDescription)
            Logger.error("Restore failed: \(error)")
        }
    }

    // MARK: - Subscription Warning Sheet

    private var subscriptionWarningSheet: some View {
        ZStack {
            Color(hex: "1F2937").ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)

                Text("Active Subscription")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 16) {
                    Text("⚠️ You have an active \(subscriptionState.currentTier.displayName) subscription.")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Deleting your account will NOT automatically cancel your subscription. Apple will continue to charge you.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Please cancel your subscription first before deleting your account.")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                VStack(spacing: 12) {
                    // Cancel Subscription Button (Primary)
                    Button(action: {
                        showSubscriptionWarningBeforeDelete = false
                        openSubscriptionManagement()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel Subscription First")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Delete Anyway Button (Secondary)
                    Button(action: {
                        showSubscriptionWarningBeforeDelete = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.showDeleteAccountWarning = true
                        }
                    }) {
                        Text("Delete Anyway (Keep Paying)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .padding(.top, 8)

                    // Go Back Button
                    Button("Go Back") {
                        showSubscriptionWarningBeforeDelete = false
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(24)
        }
        .modifier(PresentationDetentsModifier())
    }
}

// Helper for Bullet Points
struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
            Text(text)
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}

// MARK: - Subviews

struct PrivacyBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "5EEAD4")) // teal-300
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy First")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Your recordings are processed locally and encrypted. We never listen to your audio.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(colors: [Color(hex: "134E4A"), Color(hex: "0F766E")], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "5EEAD4").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Compatibility Modifiers

struct PresentationDetentsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.fraction(0.85)])
        } else {
            content
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 16)
            
            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .background(Material.ultraThin)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundStyle(Color(hex: "2DD4BF")) // teal-400
            
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.caption)
            }
        }
        .padding(.vertical, 12)
        // Add divider logic if needed, but spacing usually enough in clean designs
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 24)
                .foregroundStyle(Color(hex: "2DD4BF")) // teal-400
            
            Text(title)
                .foregroundStyle(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "2DD4BF"))
        }
        .padding(.vertical, 8)
    }
}

// Simple Subview for Usage
struct UsageView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "115E59").ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Billing History")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    Text("Total Usage Cost")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(viewModel.usageCost)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(40)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}
