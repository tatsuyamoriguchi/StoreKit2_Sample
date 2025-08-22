//
//  StoreView.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/20/25.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    
    @StateObject private var storeManager = StoreManager.shared
    @State private var purchasingProductID: String? = nil

    
    var body: some View {
        NavigationView {
            List {
                Section("Auto-Renewing Subscriptions") {
                    ForEach(storeManager.products.filter { $0.type == .autoRenewable }) { p in
                        productRow(p)
                    }
                }
                Section("Non-Renewing Subscriptions") {
                    ForEach(storeManager.products.filter { $0.type == .nonRenewable }) { p in
                        productRow(p)
                    }
                }
                Section("Events") {
                    ForEach(storeManager.products.filter { $0.type == .nonConsumable }) { p in
                        productRow(p)
                    }
                }
                Section("Sleep Goods") {
                    ForEach(storeManager.products.filter { $0.type == .consumable }) { p in
                        productRow(p)
                    }
                }
            }
        }
        .task { await storeManager.requestProducts() }
        .navigationTitle("Sleep Tracer Store")
    }
        
    @ViewBuilder
    func productRow(_ p: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.displayName)
                Text(storeManager.productIdToEmoji[p.id] ?? "")
            }
            Text(p.description)

            Button {
                Task {
                    do {
                        purchasingProductID = p.id
                        let transaction = try await storeManager.purchase(p)
                        print("✅ Purchased: \(transaction?.productID ?? "nil")")
                    } catch {
                        print("⚠️ Purchase failed: \(error)")
                    }
                    purchasingProductID = nil
                }
            } label: {
                if storeManager.purchasedIdentifiers.contains(p.id) {
                    Label("Purchased", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if purchasingProductID == p.id {
                    ProgressView() // spinner while purchasing
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text(priceLabel(for: p))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(10)
                }
            }
            .disabled(purchasingProductID == p.id) // disable a button only pressed

            
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
    
    private func priceLabel(for product: Product) -> String {
        if product.type == .autoRenewable {
            return "\(product.displayPrice) / month"
        } else {
            return product.displayPrice
        }
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
