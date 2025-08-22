//
//  StoreManager.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/21/25.
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager() // Singleton (shared instance)

    @Published var purchasedIdentifiers: Set<String> = []

    // Update purchased IDs
    func updatePurchasedIdentifiers(_ transaction: Transaction) {
        purchasedIdentifiers.insert(transaction.productID)
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let currentAccountToken = UUID() // Use userId for Fax Echo
        let result = try await product.purchase(options: [.appAccountToken(currentAccountToken)])
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            StoreManager.shared.updatePurchasedIdentifiers(transaction)
            await transaction.finish()
            return transaction
        case .pending, .userCancelled:
            return nil
        default:
            return nil
            
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let value):
            return value
        }
    }
    
    enum StoreKitError: Error {
        case failedVerification
    }
    

}

