//
//  StoreView.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/20/25.
//

import SwiftUI
import StoreKit

func loadProductEmojis() -> [String: String] {
    guard let url = Bundle.main.url(forResource: "Products", withExtension: "plist"),
          let data = try? Data(contentsOf: url) else {
        print("⚠️ Could not find Products.plist in bundle")
        return [:]
    }
    
    do {
        if let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            return dict
        } else {
            print("⚠️ Products.plist not a [String: String]")
            return [:]
        }
    } catch {
        print("⚠️ Failed to decode Products.plist: \(error)")
        return [:]
    }
}

struct StoreView: View {
    @State private var products: [StoreKit.Product] = []
    private static let productIdToEmoji = loadProductEmojis()
    private let productIdToEmoji = StoreView.productIdToEmoji
        
    

    
    var body: some View {
        NavigationView {
            List {
                Section("Auto-Renewing Subscriptions") {
                    ForEach(products.filter { $0.type == .autoRenewable }) { p in
                        productRow(p)
                    }
                }
                Section("Non-Renewing Subscriptions") {
                    ForEach(products.filter { $0.type == .nonRenewable }) { p in
                        productRow(p)
                    }
                }
                Section("Events") {
                    ForEach(products.filter { $0.type == .nonConsumable }) { p in
                        productRow(p)
                    }
                }
                Section("Sleep Goods") {
                    ForEach(products.filter { $0.type == .consumable }) { p in
                        productRow(p)
                    }
                }
            }
        }
        .task { await requestProducts() }
        .navigationTitle("Sleep Tracer Store")
    }
    
    @MainActor
    private func requestProducts() async {
        do {
            let ids = Set(productIdToEmoji.keys)
            let fetched = try await StoreKit.Product.products(for: ids) // note the StoreKit. prefix
            products = fetched.sorted { $0.displayName < $1.displayName }
        } catch {
            print("Failed product request: \(error)")
        }
    }
    
    @ViewBuilder
    func productRow(_ p: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.displayName)
                Text(productIdToEmoji[p.id] ?? "")
            }
            Text(p.description)
            Text(p.displayPrice)
            if p.isFamilyShareable.description == "true" {
                Text("Family Shareable")
                    .foregroundStyle(Color.red)
            }

            if let offer = p.subscription?.introductoryOffer {
                if offer.paymentMode == .freeTrial {
                    Text("Free Trial: \(offer.period.debugDescription)")
                        .foregroundStyle(Color.teal)
                } else {
                    Text("Intro Offer: \(offer.paymentMode.rawValue) for \(offer.period.debugDescription)")
                }
            }
            
        }
        .padding(.vertical, 4)
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let currentAccountToken = UUID() // Use userId for Fax Echo
        let result = try await product.purchase(options: [.appAccountToken(currentAccountToken)])
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await StoreManager.shared.updatePurchasedIdentifiers(transaction)
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



#Preview {
    
    StoreView()
}

/*
 Seminar as part of an auto-renewable subscription
 You can bundle access to the seminar as an entitlement.
 Anyone who is an active subscriber (or uses a free trial / offer code) automatically gets the seminar.
 In Swift/StoreKit 2, check Transaction.currentEntitlements to determine what the subscriber is allowed to access.
 
 Practical setup for your use case
 Create an auto-renewable subscription product (e.g., “Monthly Seminar Access”).
 In your app, map subscription entitlement → seminar access.
 Optionally, create offer codes in App Store Connect for the subscription, so new users or lapsed subscribers can get a free trial.
 Use StoreKit 2 APIs:
 let entitlements = await Transaction.currentEntitlements
 if entitlements.contains(where: { $0.productID == "com.yourapp.monthly_seminar" }) {
     // Grant access to seminar content
 }
 Non-subscription seminars (one-time) remain non-consumable and cannot use offer codes. You’d manage any free access yourself.
 💡 Key point:
 Offer codes only work with auto-renewable subscriptions.
 If you want subscribers to get free seminars automatically, bundle the seminars behind an active subscription.
 
 */
