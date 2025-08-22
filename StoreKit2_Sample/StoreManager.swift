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
}

