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
    @Published var products: [Product] = []
    private(set) var productIdToEmoji: [String: String] = [:]
    private init() {
        loadProductEmojis()
    }
    
    // Fetch products
    func requestProducts() async {
        do {
            let ids = Set(productIdToEmoji.keys)
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted { $0.displayName < $1.displayName }
            
            // ✅ Check if already purchased
            for product in products {
                if try await isPurchased(product.id) {
                    purchasedIdentifiers.insert(product.id)
                }
            }
        } catch {
            print("⚠️ Failed product request: \(error)")
        }
    }
    
    private func loadProductEmojis() {
        guard let url = Bundle.main.url(forResource: "Products", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ Could not find Products.plist in bundle")
            return
        }
        
        do {
            if let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
                productIdToEmoji = dict
            } else {
                print("⚠️ Products.plist not a [String: String]")
            }
        } catch {
            print("⚠️ Failed to decode Products.plist: \(error)")
        }
    }
    
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
    
    func listenForTransactions() async {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedIdentifiers(transaction)
                    await transaction.finish()
                    print("✅ Transaction processed: \(transaction.productID)")
                } catch {
                    print("Transazation failed verification")
                }
            }
        }
    }
    
    func isPurchased(_ productIdentifier: String) async throws -> Bool {
        guard let result = await Transaction.latest(for: productIdentifier) else {
            return false
        }
        
        let transaction = try checkVerified(result)
        return transaction.revocationDate == nil && !transaction.isUpgraded
    }
    

}

