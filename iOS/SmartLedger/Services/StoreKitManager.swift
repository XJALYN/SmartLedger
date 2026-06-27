import Foundation
import StoreKit

enum StoreKitError: LocalizedError, Equatable {
    case productNotFound
    case purchaseCancelled
    case purchasePending
    case purchaseFailed
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .productNotFound: return String(localized: "iap.error.product_not_found")
        case .purchaseCancelled: return String(localized: "iap.error.cancelled")
        case .purchasePending: return String(localized: "iap.error.pending")
        case .purchaseFailed: return String(localized: "iap.error.failed")
        case .unverifiedTransaction: return String(localized: "iap.error.unverified")
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchasingProductID: String?

    private var updatesTask: Task<Void, Never>?
    private weak var settings: AppSettings?

    private init() {}

    func start(settings: AppSettings) {
        self.settings = settings
        updatesTask?.cancel()
        updatesTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        let ids = Set(CreditRechargeOption.all.map(\.productID))
        do {
            let loaded = try await Product.products(for: ids)
            products = loaded.sorted {
                (CreditRechargeOption.credits(for: $0.id) ?? 0) < (CreditRechargeOption.credits(for: $1.id) ?? 0)
            }
        } catch {
            products = []
        }
    }

    func product(for option: CreditRechargeOption) -> Product? {
        products.first { $0.id == option.productID }
    }

    func displayPrice(for option: CreditRechargeOption) -> String {
        if let price = product(for: option)?.displayPrice {
            return price
        }
        return String(localized: String.LocalizationValue(option.fallbackPriceKey))
    }

    func purchase(option: CreditRechargeOption) async throws -> Int {
        guard let settings else { throw StoreKitError.purchaseFailed }

        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            settings.rechargeCredits(option.credits)
            return option.credits
        }

        if products.isEmpty {
            await loadProducts()
        }

        guard let product = product(for: option) else {
            throw StoreKitError.productNotFound
        }

        purchasingProductID = product.id
        defer { purchasingProductID = nil }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            let credits = fulfill(transaction, settings: settings)
            await transaction.finish()
            return credits
        case .userCancelled:
            throw StoreKitError.purchaseCancelled
        case .pending:
            throw StoreKitError.purchasePending
        @unknown default:
            throw StoreKitError.purchaseFailed
        }
    }

    func restorePurchases() async -> Int {
        guard let settings else { return 0 }

        var restoredCredits = 0
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            restoredCredits += fulfill(transaction, settings: settings)
            await transaction.finish()
        }

        for await result in Transaction.unfinished {
            guard let transaction = try? checkVerified(result) else { continue }
            restoredCredits += fulfill(transaction, settings: settings)
            await transaction.finish()
        }

        return restoredCredits
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let settings else { continue }
            guard let transaction = try? checkVerified(result) else { continue }
            _ = fulfill(transaction, settings: settings)
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }

    @discardableResult
    private func fulfill(_ transaction: Transaction, settings: AppSettings) -> Int {
        let transactionID = String(transaction.id)
        guard !settings.hasFulfilledTransaction(transactionID) else { return 0 }
        guard let credits = CreditRechargeOption.credits(for: transaction.productID) else { return 0 }

        settings.markTransactionFulfilled(transactionID)
        settings.rechargeCredits(credits)
        return credits
    }
}
