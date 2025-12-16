//
//  SubscriptionService.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    // Product identifiers
    static let premiumMonthlyProductId = "com.taxguard.1099.premium.monthly"
    static let premiumAnnualProductId = "com.taxguard.1099.premium.annual"
    
    // Free tier limits
    static let freeIncomeLimit: Double = 10_000
    
    // Published properties
    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Computed properties
    var isPremium: Bool {
        !purchasedProductIds.isEmpty
    }
    
    var hasExceededFreeLimit: Bool {
        // This would be calculated based on actual income data
        return false
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let productIds = [
                Self.premiumMonthlyProductId,
                Self.premiumAnnualProductId
            ]
            
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIds.insert(transaction.productID)
            }
        }
    }
    
    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        var purchasedIds: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchasedIds.insert(transaction.productID)
            }
        }
        
        purchasedProductIds = purchasedIds
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Get Product
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
    
    var monthlyProduct: Product? {
        product(for: Self.premiumMonthlyProductId)
    }
    
    var annualProduct: Product? {
        product(for: Self.premiumAnnualProductId)
    }
    
    // MARK: - Feature Access
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedIncome:
            return isPremium
        case .receiptPhotos:
            return isPremium
        case .allDeductionCategories:
            return isPremium
        case .yearEndReports:
            return isPremium
        case .pdfExport:
            return isPremium
        case .prioritySupport:
            return isPremium
        case .basicTracking:
            return true // Free for everyone
        }
    }
    
    func checkIncomeLimit(currentTotal: Double) -> Bool {
        if isPremium {
            return true
        }
        return currentTotal < Self.freeIncomeLimit
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable {
    case unlimitedIncome = "Unlimited Income Tracking"
    case receiptPhotos = "Receipt Photo Capture"
    case allDeductionCategories = "All Deduction Categories"
    case yearEndReports = "Year-End Reports"
    case pdfExport = "PDF Export"
    case prioritySupport = "Priority Support"
    case basicTracking = "Basic Income Tracking"
    
    var icon: String {
        switch self {
        case .unlimitedIncome:
            return "infinity"
        case .receiptPhotos:
            return "camera.fill"
        case .allDeductionCategories:
            return "list.bullet.rectangle.fill"
        case .yearEndReports:
            return "chart.bar.doc.horizontal.fill"
        case .pdfExport:
            return "doc.fill"
        case .prioritySupport:
            return "star.fill"
        case .basicTracking:
            return "checkmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedIncome:
            return "Track income beyond $10K/year"
        case .receiptPhotos:
            return "Capture and store receipt photos"
        case .allDeductionCategories:
            return "Access all 13 deduction categories"
        case .yearEndReports:
            return "Comprehensive year-end tax summary"
        case .pdfExport:
            return "Export reports for your tax preparer"
        case .prioritySupport:
            return "Get help when you need it"
        case .basicTracking:
            return "Track up to $10K annual income"
        }
    }
    
    var isFree: Bool {
        return self == .basicTracking
    }
}
