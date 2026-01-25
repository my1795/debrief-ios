//
//  SubscriptionState.swift
//  debrief
//
//  Global subscription state management
//

import Foundation
import Combine
import RevenueCat

/// Subscription tier enum - matches backend
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "FREE"
    case personal = "PERSONAL"
    case pro = "PRO"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .personal: return "Personal"
        case .pro: return "Pro"
        }
    }

    var weeklyDebriefLimit: Int {
        switch self {
        case .free: return BillingConstants.Tier.free.weeklyDebriefLimit
        case .personal: return BillingConstants.Tier.personal.weeklyDebriefLimit
        case .pro: return BillingConstants.Tier.pro.weeklyDebriefLimit
        }
    }

    var weeklyMinutesLimit: Int {
        switch self {
        case .free: return BillingConstants.Tier.free.weeklyMinutesLimit
        case .personal: return BillingConstants.Tier.personal.weeklyMinutesLimit
        case .pro: return BillingConstants.Tier.pro.weeklyMinutesLimit
        }
    }

    var storageLimitMB: Int {
        switch self {
        case .free: return BillingConstants.Tier.free.storageLimitMB
        case .personal: return BillingConstants.Tier.personal.storageLimitMB
        case .pro: return BillingConstants.Tier.pro.storageLimitMB
        }
    }

    var isUnlimitedDebriefs: Bool { weeklyDebriefLimit == Int.max }
    var isUnlimitedMinutes: Bool { weeklyMinutesLimit == Int.max }
    var isUnlimitedStorage: Bool { storageLimitMB == Int.max }
}

/// Global subscription state - singleton for app-wide access
@MainActor
class SubscriptionState: ObservableObject {
    static let shared = SubscriptionState()

    // MARK: - Published State

    @Published var currentTier: SubscriptionTier = .free
    @Published var isSubscribed: Bool = false
    @Published var expiresAt: Date?
    @Published var willRenew: Bool = true  // Will subscription auto-renew?
    @Published var offerings: [Package] = []

    // Usage tracking (from Firestore UserPlan)
    @Published var usedDebriefs: Int = 0
    @Published var usedMinutes: Int = 0
    @Published var usedStorageMB: Int = 0

    // Limits - computed from current tier (NOT stored separately)
    var weeklyDebriefLimit: Int { currentTier.weeklyDebriefLimit }
    var weeklyMinutesLimit: Int { currentTier.weeklyMinutesLimit }
    var storageLimitMB: Int { currentTier.storageLimitMB }

    // UI State
    @Published var showPaywall: Bool = false
    @Published var paywallReason: QuotaExceededReason?
    @Published var hasDismissedWarningBanner: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Observe UserPlan changes from Firestore
        setupFirestoreObserver()
    }

    // MARK: - Computed Properties

    /// Usage percentage for debriefs (0-100+)
    var debriefUsagePercent: Double {
        guard weeklyDebriefLimit != Int.max, weeklyDebriefLimit > 0 else { return 0 }
        return Double(usedDebriefs) / Double(weeklyDebriefLimit) * 100
    }

    /// Usage percentage for minutes (0-100+)
    var minutesUsagePercent: Double {
        guard weeklyMinutesLimit != Int.max, weeklyMinutesLimit > 0 else { return 0 }
        return Double(usedMinutes) / Double(weeklyMinutesLimit) * 100
    }

    /// Usage percentage for storage (0-100+)
    var storageUsagePercent: Double {
        guard storageLimitMB != Int.max, storageLimitMB > 0 else { return 0 }
        return Double(usedStorageMB) / Double(storageLimitMB) * 100
    }

    /// Highest usage percentage across all metrics
    var highestUsagePercent: Double {
        max(debriefUsagePercent, minutesUsagePercent, storageUsagePercent)
    }

    /// Should show upgrade warning banner (80%+ usage)
    var shouldShowUpgradeBanner: Bool {
        guard currentTier == .free else { return false }
        guard !hasDismissedWarningBanner else { return false }
        return highestUsagePercent >= 80
    }

    /// Can user record (not at 100% quota)
    var canRecord: Bool {
        // FREE tier checks
        if currentTier == .free {
            let debriefOk = weeklyDebriefLimit == Int.max || usedDebriefs < weeklyDebriefLimit
            let minutesOk = weeklyMinutesLimit == Int.max || usedMinutes < weeklyMinutesLimit
            let storageOk = storageLimitMB == Int.max || usedStorageMB < storageLimitMB
            return debriefOk && minutesOk && storageOk
        }
        // Paid tiers have generous limits
        return true
    }

    /// Get the reason why recording is blocked (if any)
    var quotaExceededReason: QuotaExceededReason? {
        guard currentTier == .free else { return nil }

        if weeklyDebriefLimit != Int.max && usedDebriefs >= weeklyDebriefLimit {
            return .weeklyDebriefLimit
        }
        if weeklyMinutesLimit != Int.max && usedMinutes >= weeklyMinutesLimit {
            return .weeklyMinutesLimit
        }
        if storageLimitMB != Int.max && usedStorageMB >= storageLimitMB {
            return .storageLimit
        }
        return nil
    }

    // MARK: - Sync Methods

    /// Sync state with RevenueCat CustomerInfo
    func syncWithRevenueCat(customerInfo: CustomerInfo) {
        // Debug: Log all entitlements
        Logger.info("🔍 RevenueCat entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
        for (key, entitlement) in customerInfo.entitlements.all {
            Logger.info("  - \(key): active=\(entitlement.isActive), willRenew=\(entitlement.willRenew), expires=\(entitlement.expirationDate?.description ?? "nil")")
        }

        // Determine tier from entitlements
        if let proEntitlement = customerInfo.entitlements[RevenueCatConstants.Entitlements.pro],
           proEntitlement.isActive {
            currentTier = .pro
            isSubscribed = true
            expiresAt = proEntitlement.expirationDate
            willRenew = proEntitlement.willRenew
            Logger.info("✅ Tier set to PRO (willRenew=\(willRenew))")
        } else if let personalEntitlement = customerInfo.entitlements[RevenueCatConstants.Entitlements.personal],
                  personalEntitlement.isActive {
            currentTier = .personal
            isSubscribed = true
            expiresAt = personalEntitlement.expirationDate
            willRenew = personalEntitlement.willRenew
            Logger.info("✅ Tier set to PERSONAL (willRenew=\(willRenew))")
        } else {
            currentTier = .free
            isSubscribed = false
            expiresAt = nil
            willRenew = true
            Logger.info("ℹ️ Tier set to FREE (no active entitlements)")
        }

        Logger.info("📊 SubscriptionState: tier=\(currentTier.displayName), subscribed=\(isSubscribed), willRenew=\(willRenew)")
    }

    /// Sync usage data from Firestore UserPlan (NOT tier - tier comes from RevenueCat only)
    func syncWithUserPlan(_ userPlan: UserPlan) {
        // Only sync usage data from Firestore - tier is managed by RevenueCat
        usedDebriefs = userPlan.weeklyUsage.debriefCount
        usedMinutes = userPlan.usedMinutes
        usedStorageMB = userPlan.usedStorageMB

        Logger.debug("Usage synced: \(usedDebriefs)/\(weeklyDebriefLimit) debriefs, \(usedMinutes)/\(weeklyMinutesLimit) min")
    }

    // MARK: - Private

    private func setupFirestoreObserver() {
        // Observe auth state to start UserPlan listener
        AuthSession.shared.$user
            .compactMap { $0?.id }
            .removeDuplicates()
            .sink { [weak self] userId in
                self?.observeUserPlan(userId: userId)
            }
            .store(in: &cancellables)
    }

    private func observeUserPlan(userId: String) {
        FirestoreService.shared.observeUserPlan(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Logger.error("UserPlan observation error: \(error)")
                }
            }, receiveValue: { [weak self] userPlan in
                self?.syncWithUserPlan(userPlan)
            })
            .store(in: &cancellables)
    }

    // MARK: - Actions

    /// Show paywall with optional reason
    func presentPaywall(reason: QuotaExceededReason? = nil) {
        paywallReason = reason
        showPaywall = true
    }

    /// Dismiss upgrade warning banner
    func dismissWarningBanner() {
        hasDismissedWarningBanner = true
    }

    /// Reset warning banner dismissal (call on new billing week)
    func resetWarningBannerDismissal() {
        hasDismissedWarningBanner = false
    }
}
