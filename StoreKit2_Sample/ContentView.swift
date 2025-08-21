//
//  ContentView.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/20/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                
               NavigationLink("Go To Store") {
                   StoreView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
