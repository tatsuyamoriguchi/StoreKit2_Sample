//
//  ContentView.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                
                NavigationLink("Go To Store") {

                    StoreView(storeManager: storeManager)
                        .task {
                            // Start listening for transactions immediately, in background
                            await storeManager.listenForTransactions()
                        }
                }
            }
            .padding()
            
        }
    }
}

#Preview {
    ContentView()
}
