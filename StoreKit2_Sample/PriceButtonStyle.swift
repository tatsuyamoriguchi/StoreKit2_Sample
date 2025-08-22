//
//  PriceButtonStyle.swift
//  StoreKit2_Sample
//
//  Created by Tatsuya Moriguchi on 8/22/25.
//

import Foundation
import SwiftUI

struct PriceButtonStyle: ButtonStyle {
    enum State {
        case normal
        case purchased
        case loading
    }
    
    var state: State
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(backgroundColor(configuration))
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
    
    private func backgroundColor(_ configuration: Configuration) -> Color {
        switch state {
        case .normal: return .blue
        case .purchased: return .green
        case .loading: return .gray.opacity(0.4)
        }
    }
}
