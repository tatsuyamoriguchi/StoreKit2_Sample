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
        List(products) { p in
            HStack {
                Text(p.displayName)          // StoreKit 2 API
                Text(productIdToEmoji[p.id] ?? "")
            }
        }
        .task { await requestProducts() }     // Fetch on appear
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
    
}



#Preview {
    
    StoreView()
}
