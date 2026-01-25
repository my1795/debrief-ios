//
//  SubscriptionService.swift
//  debrief
//
//  RevenueCat SDK wrapper for subscription management
//

import Foundation
import Combine
import RevenueCat

/// RevenueCat subscription service wrapper
@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()

    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading = false
    @Published var error: Error?

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Configure RevenueCat SDK - call this on app launch
    func configure(appUserID: String? = nil) {
        let apiKey = AppConfig.shared.revenueCatAPIKey
        let environment = AppConfig.shared.currentEnvironment
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"

        // Set log level based on environment
        Purchases.logLevel = AppConfig.shared.isVerboseLoggingEnabled ? .debug : .warn

        Logger.info("🔑 RevenueCat API Key: \(apiKey.prefix(15))... (env: \(environment.displayName))")
        Logger.info("📦 Bundle ID: \(bundleID)")

        var configuration = Configuration.Builder(withAPIKey: apiKey)

        if let userID = appUserID {
            configuration = configuration.with(appUserID: userID)
        }

        Purchases.configure(with: configuration.build())
        Purchases.shared.delegate = self

        Logger.info("RevenueCat configured with appUserID: \(appUserID ?? "anonymous")")
    }

    // MARK: - User Management

    /// Login user with Firebase UID - call after Firebase auth
    func login(userID: String) async throws {
        Logger.info("RevenueCat logging in user: \(userID)")
        let (customerInfo, _) = try await Purchases.shared.logIn(userID)
        self.customerInfo = customerInfo

        // Sync subscription state from RevenueCat (source of truth)
        SubscriptionState.shared.syncWithRevenueCat(customerInfo: customerInfo)
        Logger.success("RevenueCat login successful - Tier: \(SubscriptionState.shared.currentTier.displayName)")
    }

    /// Logout user - call on Firebase sign out
    func logout() async throws {
        Logger.info("RevenueCat logging out user")
        let customerInfo = try await Purchases.shared.logOut()
        self.customerInfo = customerInfo

        // Reset subscription state to FREE
        SubscriptionState.shared.syncWithRevenueCat(customerInfo: customerInfo)
        Logger.success("RevenueCat logout successful")
    }

    // MARK: - Offerings

    /// Fetch available subscription offerings
    func fetchOfferings() async throws -> Offerings {
        isLoading = true
        defer { isLoading = false }

        let offerings = try await Purchases.shared.offerings()
        self.offerings = offerings
        Logger.info("Fetched offerings: \(offerings.all.count) available")
        return offerings
    }

    /// Get current offering (default paywall packages)
    var currentOffering: Offering? {
        offerings?.current
    }

    // MARK: - Purchase

    /// Purchase a package
    func purchase(package: Package) async throws -> CustomerInfo {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let startTime = Date()
        Logger.info("🛒 [T+0.0s] Starting purchase: \(package.identifier)")

        do {
            let result = try await Purchases.shared.purchase(package: package)
            let purchaseTime = Date().timeIntervalSince(startTime)
            Logger.info("🛒 [T+\(String(format: "%.1f", purchaseTime))s] RevenueCat purchase completed")

            self.customerInfo = result.customerInfo

            if !result.userCancelled {
                // Explicitly sync subscription state (don't rely only on delegate)
                SubscriptionState.shared.syncWithRevenueCat(customerInfo: result.customerInfo)
                let syncTime = Date().timeIntervalSince(startTime)
                Logger.success("🛒 [T+\(String(format: "%.1f", syncTime))s] State synced - Tier: \(SubscriptionState.shared.currentTier.displayName)")
            } else {
                Logger.info("Purchase cancelled by user")
            }

            return result.customerInfo
        } catch {
            self.error = error
            Logger.error("Purchase failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        isLoading = true
        error = nil
        defer { isLoading = false }

        Logger.info("Restoring purchases...")

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo

            // Explicitly sync subscription state
            SubscriptionState.shared.syncWithRevenueCat(customerInfo: customerInfo)
            Logger.success("Restore successful - Tier: \(SubscriptionState.shared.currentTier.displayName)")

            return customerInfo
        } catch {
            self.error = error
            Logger.error("Restore failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Entitlements

    /// Get current customer info
    func getCustomerInfo() async throws -> CustomerInfo {
        let customerInfo = try await Purchases.shared.customerInfo()
        self.customerInfo = customerInfo
        return customerInfo
    }

    /// Force refresh subscription status from RevenueCat (invalidates cache)
    func refreshSubscriptionStatus() async throws {
        Logger.info("🔄 Refreshing subscription status (invalidating cache)...")

        // Invalidate cache to force fresh fetch from RevenueCat servers
        Purchases.shared.invalidateCustomerInfoCache()

        let customerInfo = try await Purchases.shared.customerInfo()
        self.customerInfo = customerInfo

        // Sync with SubscriptionState
        SubscriptionState.shared.syncWithRevenueCat(customerInfo: customerInfo)

        // Log detailed status with time comparison
        let now = Date()
        Logger.info("  Current time: \(now)")

        if let proEntitlement = customerInfo.entitlements[RevenueCatConstants.Entitlements.pro] {
            let timeUntilExpiry = proEntitlement.expirationDate.map { $0.timeIntervalSince(now) } ?? 0
            Logger.info("  Pro: active=\(proEntitlement.isActive), willRenew=\(proEntitlement.willRenew), expires=\(proEntitlement.expirationDate?.description ?? "nil"), timeUntilExpiry=\(Int(timeUntilExpiry))s")
        }
        if let personalEntitlement = customerInfo.entitlements[RevenueCatConstants.Entitlements.personal] {
            let timeUntilExpiry = personalEntitlement.expirationDate.map { $0.timeIntervalSince(now) } ?? 0
            Logger.info("  Personal: active=\(personalEntitlement.isActive), willRenew=\(personalEntitlement.willRenew), expires=\(personalEntitlement.expirationDate?.description ?? "nil"), timeUntilExpiry=\(Int(timeUntilExpiry))s")
        }

        Logger.success("🔄 Refresh complete - Current tier: \(SubscriptionState.shared.currentTier.displayName)")
    }

    /// Check if user has active entitlement
    func hasEntitlement(_ entitlementID: String) -> Bool {
        customerInfo?.entitlements[entitlementID]?.isActive ?? false
    }

    /// Get current subscription tier based on entitlements
    var currentTier: SubscriptionTier {
        guard let info = customerInfo else { return .free }

        // Check entitlements in order of priority
        if info.entitlements[RevenueCatConstants.Entitlements.pro]?.isActive == true {
            return .pro
        }
        if info.entitlements[RevenueCatConstants.Entitlements.personal]?.isActive == true {
            return .personal
        }
        return .free
    }

    /// Check if user is subscribed (any paid tier)
    var isSubscribed: Bool {
        currentTier != .free
    }

    /// Get subscription expiration date
    var expirationDate: Date? {
        guard let info = customerInfo else { return nil }

        // Check pro first, then personal
        if let proExpiry = info.entitlements[RevenueCatConstants.Entitlements.pro]?.expirationDate {
            return proExpiry
        }
        if let personalExpiry = info.entitlements[RevenueCatConstants.Entitlements.personal]?.expirationDate {
            return personalExpiry
        }
        return nil
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            Logger.info("CustomerInfo updated - Tier: \(self.currentTier.rawValue)")

            // Notify SubscriptionState of changes
            SubscriptionState.shared.syncWithRevenueCat(customerInfo: customerInfo)
        }
    }
}

// MARK: - RevenueCat Constants

enum RevenueCatConstants {
    enum Entitlements {
        static let personal = "personal"
        static let pro = "pro"
    }

    enum ProductIDs {
        static let personalMonthly = "debrief_personal_monthly"
        static let proMonthly = "debrief_pro_monthly"
    }
}
