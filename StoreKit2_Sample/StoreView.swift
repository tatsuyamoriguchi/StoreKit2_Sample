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
                        ProductRow(p)
                    }
                }
                Section("Non-Renewing Subscriptions") {
                    ForEach(products.filter { $0.type == .nonRenewable }) { p in
                        ProductRow(p)
                    }
                }
                Section("Non-Consumables") {
                    ForEach(products.filter { $0.type == .nonConsumable }) { p in
                        ProductRow(p)
                    }
                }
                Section("Consumables") {
                    ForEach(products.filter { $0.type == .consumable }) { p in
                        ProductRow(p)
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
    func ProductRow(_ p: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.displayName)
                Text(productIdToEmoji[p.id] ?? "")
            }
            Text(p.description)
            Text(p.displayPrice)
            if p.isFamilyShareable.description == "true" {
                Text("Family Shareable")
            }

            if let offer = p.subscription?.introductoryOffer {
                if offer.paymentMode == .freeTrial {
                    Text("Free Trial: \(offer.period.debugDescription)")
                } else {
                    Text("Intro Offer: \(offer.paymentMode.rawValue) for \(offer.period.debugDescription)")
                }
//            } else {
//                Text("No intro offer available")
            }
            
        }
        .padding(.vertical, 4)
    }
    
}



#Preview {
    
    StoreView()
}
