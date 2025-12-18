//
//  EmptyStateView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.cardBackgroundLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(Theme.textSecondary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
                
                Text(message)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .padding()
    }
}

#Preview {
    ZStack {
        Theme.electricBlue.ignoresSafeArea()
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No Incomes Yet",
            message: "Tap the + button to track your first payment."
        )
    }
}
