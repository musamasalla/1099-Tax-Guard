//
//  PaywallView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var subscriptionService = SubscriptionService.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            ElectricBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features list
                    featuresSection
                    
                    // Pricing
                    pricingSection
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Restore purchases
                    restoreButton
                    
                    // Terms
                    termsSection
                }
                .padding()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.premiumGradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: Theme.accentPurple.opacity(0.4), radius: 15)
            
            VStack(spacing: 8) {
                Text("Go Premium")
                    .font(Theme.largeTitleFont)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Unlock all features and maximize your tax savings")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(PremiumFeature.allCases.filter { !$0.isFree }, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .foregroundColor(Theme.primaryGreen)
                        .font(.title3)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.rawValue)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(feature.description)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscriptionService.isLoading {
                ProgressView()
                    .tint(Theme.primaryGreen)
            } else {
                ForEach(subscriptionService.products, id: \.id) { product in
                    PricingCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPopular: product.id == SubscriptionService.premiumMonthlyProductId
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
        .onAppear {
            // Select first product by default
            if selectedProduct == nil {
                selectedProduct = subscriptionService.products.first
            }
        }
    }
    
    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button(action: purchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start 7-Day Free Trial")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle(gradient: Theme.premiumGradient))
        .disabled(selectedProduct == nil || isPurchasing)
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button(action: restore) {
            Text("Restore Purchases")
                .font(Theme.captionFont)
                .foregroundColor(Theme.primaryBlue)
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("7-day free trial, then $10/month. Cancel anytime.")
                .font(.caption2)
                .foregroundColor(Theme.textMuted)
            
            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://example.com/terms")!)
                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption2)
            .foregroundColor(Theme.primaryBlue)
        }
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Actions
    private func purchase() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let transaction = try await subscriptionService.purchase(product)
                if transaction != nil {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }
    
    private func restore() {
        Task {
            await subscriptionService.restorePurchases()
            if subscriptionService.isPremium {
                dismiss()
            }
        }
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isPopular {
                    Text("MOST POPULAR")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentGold)
                        .cornerRadius(4)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(product.description)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        if product.id.contains("monthly") {
                            Text("/month")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        } else {
                            Text("/year")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Theme.cardBackgroundLight : Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.accentPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    PaywallView()
}
