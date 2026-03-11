//
//  SubscriptionManager.swift
//  LootsDisplay
//
//  Created by Nat on 3/9/26.
//


import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // 🔁 Replace with your actual product ID from App Store Connect
    private let proProductID = "com.labelsensordata.pro.monthly"

@Published var isProUnlocked: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [proProductID])
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase
    func purchase() async throws {
        guard let product = products.first else { return }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshPurchaseStatus()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            print("Restore failed: \(error)")
        }
        isLoading = false
    }

    // MARK: - Check Status
    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == proProductID && transaction.revocationDate == nil {
                    isProUnlocked = true
                    return
                }
            }
        }
        isProUnlocked = false
    }

    // MARK: - Listen for Transactions (handles renewals, refunds, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.refreshPurchaseStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
