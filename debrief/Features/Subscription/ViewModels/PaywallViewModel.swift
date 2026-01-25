//
//  PaywallViewModel.swift
//  debrief
//
//  ViewModel for the paywall/upgrade screen
//

import Foundation
import Combine
import RevenueCat

/// Parsed offering metadata from RevenueCat
struct OfferingMetadata {
    let freeStorageMB: Int
    let freeWeeklyDebriefs: Int
    let freeWeeklyMinutes: Int
    let personalStorageMB: Int
    let personalWeeklyDebriefs: Int
    let personalWeeklyMinutes: Int
    let proStorageMB: Int
    let proWeeklyDebriefs: Int
    let proWeeklyMinutes: Int

    static let fallback = OfferingMetadata(
        freeStorageMB: 500,
        freeWeeklyDebriefs: 50,
        freeWeeklyMinutes: 30,
        personalStorageMB: 5000,
        personalWeeklyDebriefs: -1,
        personalWeeklyMinutes: 150,
        proStorageMB: -1,
        proWeeklyDebriefs: -1,
        proWeeklyMinutes: -1
    )

    init(from metadata: [String: Any]) {
        self.freeStorageMB = metadata["free_storageMB"] as? Int ?? 500
        self.freeWeeklyDebriefs = metadata["free_weeklyDebriefs"] as? Int ?? 50
        self.freeWeeklyMinutes = metadata["free_weeklyMinutes"] as? Int ?? 30
        self.personalStorageMB = metadata["personal_storageMB"] as? Int ?? 5000
        self.personalWeeklyDebriefs = metadata["personal_weeklyDebriefs"] as? Int ?? -1
        self.personalWeeklyMinutes = metadata["personal_weeklyMinutes"] as? Int ?? 150
        self.proStorageMB = metadata["pro_storageMB"] as? Int ?? -1
        self.proWeeklyDebriefs = metadata["pro_weeklyDebriefs"] as? Int ?? -1
        self.proWeeklyMinutes = metadata["pro_weeklyMinutes"] as? Int ?? -1
    }

    private init(freeStorageMB: Int, freeWeeklyDebriefs: Int, freeWeeklyMinutes: Int,
                 personalStorageMB: Int, personalWeeklyDebriefs: Int, personalWeeklyMinutes: Int,
                 proStorageMB: Int, proWeeklyDebriefs: Int, proWeeklyMinutes: Int) {
        self.freeStorageMB = freeStorageMB
        self.freeWeeklyDebriefs = freeWeeklyDebriefs
        self.freeWeeklyMinutes = freeWeeklyMinutes
        self.personalStorageMB = personalStorageMB
        self.personalWeeklyDebriefs = personalWeeklyDebriefs
        self.personalWeeklyMinutes = personalWeeklyMinutes
        self.proStorageMB = proStorageMB
        self.proWeeklyDebriefs = proWeeklyDebriefs
        self.proWeeklyMinutes = proWeeklyMinutes
    }

    // Helper formatters
    func formatLimit(_ value: Int, suffix: String = "") -> String {
        if value == -1 { return "Unlimited" }
        return "\(value)\(suffix)"
    }
}

@MainActor
class PaywallViewModel: ObservableObject {
    @Published var packages: [Package] = []
    @Published var selectedPackage: Package?
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var error: String?
    @Published var purchaseSuccess = false
    @Published var metadata: OfferingMetadata = .fallback

    private let subscriptionService = SubscriptionService.shared

    init() {
        Task {
            await loadOfferings()
        }
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        isLoading = true
        error = nil

        do {
            let offerings = try await subscriptionService.fetchOfferings()

            if let current = offerings.current {
                // Log all available packages for debugging
                Logger.info("📦 Available packages: \(current.availablePackages.count)")
                for pkg in current.availablePackages {
                    Logger.info("  - Package: \(pkg.identifier), Product: \(pkg.storeProduct.productIdentifier), Type: \(pkg.packageType)")
                }

                // Parse offering metadata from RevenueCat
                metadata = OfferingMetadata(from: current.metadata)
                Logger.info("📊 Offering metadata loaded: free=\(metadata.freeWeeklyDebriefs) debriefs, personal=\(metadata.personalWeeklyMinutes) min")

                // Get all packages (not just monthly - RevenueCat might classify differently)
                packages = current.availablePackages

                Logger.info("📦 Filtered packages: \(packages.count)")

                // Auto-select personal package if available (exact match)
                selectedPackage = packages.first { $0.storeProduct.productIdentifier == RevenueCatConstants.ProductIDs.personalMonthly }
                    ?? packages.first
            }
        } catch {
            self.error = "Unable to load subscription options. Please try again."
            Logger.error("Failed to load offerings: \(error)")
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase() async {
        guard let package = selectedPackage else {
            error = "Please select a plan"
            return
        }

        isPurchasing = true
        error = nil

        do {
            Logger.info("⏳ Starting purchase for \(package.storeProduct.productIdentifier)...")
            let customerInfo = try await subscriptionService.purchase(package: package)

            // Check if purchase was successful (has entitlement)
            if customerInfo.entitlements.active.count > 0 {
                // Log the new tier BEFORE setting purchaseSuccess
                Logger.success("✅ Purchase completed - New tier: \(SubscriptionState.shared.currentTier.displayName)")
                purchaseSuccess = true
            } else {
                Logger.warning("⚠️ Purchase returned but no active entitlements found")
            }
        } catch let purchaseError as RevenueCat.ErrorCode {
            switch purchaseError {
            case .purchaseCancelledError:
                // User cancelled - not an error
                Logger.info("Purchase cancelled by user")
            case .networkError:
                error = "Network error. Please check your connection."
            case .purchaseNotAllowedError:
                error = "Purchases not allowed on this device."
            case .purchaseInvalidError:
                error = "Invalid purchase. Please try again."
            default:
                error = "Purchase failed. Please try again."
            }
        } catch {
            self.error = "An unexpected error occurred. Please try again."
            Logger.error("Purchase error: \(error)")
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        error = nil

        do {
            let customerInfo = try await subscriptionService.restorePurchases()

            if customerInfo.entitlements.active.count > 0 {
                purchaseSuccess = true
                Logger.success("Restore successful - found active subscription")
            } else {
                error = "No previous purchases found."
            }
        } catch {
            self.error = "Unable to restore purchases. Please try again."
            Logger.error("Restore error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Helpers

    func selectPackage(_ package: Package) {
        selectedPackage = package
    }

    func packageForTier(_ tier: SubscriptionTier) -> Package? {
        switch tier {
        case .personal:
            return packages.first { $0.storeProduct.productIdentifier == RevenueCatConstants.ProductIDs.personalMonthly }
        case .pro:
            return packages.first { $0.storeProduct.productIdentifier == RevenueCatConstants.ProductIDs.proMonthly }
        case .free:
            return nil
        }
    }
}
