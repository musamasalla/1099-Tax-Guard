//
//  Theme.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI

// MARK: - App Theme
struct Theme {
    // MARK: - Primary Colors
    static let primaryGreen = Color(hex: "10B981") // Emerald green - safe/paid
    static let primaryRed = Color(hex: "EF4444") // Red - owed/warning
    static let primaryBlue = Color(hex: "3B82F6") // Blue - info/neutral
    
    // MARK: - Background Colors
    static let background = Color(hex: "0F172A") // Dark navy
    static let cardBackground = Color(hex: "1E293B") // Slightly lighter navy
    static let cardBackgroundLight = Color(hex: "334155") // Even lighter for nested cards
    
    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "94A3B8") // Slate gray
    static let textMuted = Color(hex: "64748B") // Darker slate
    
    // MARK: - Accent Colors
    static let accentGold = Color(hex: "F59E0B") // Amber for highlights
    static let accentPurple = Color(hex: "8B5CF6") // Purple for premium features
    
    // MARK: - Gradients
    static let greenGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let redGradient = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueGradient = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0F172A"), Color(hex: "1E293B")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Typography
    static let largeTitleFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 24, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 13, weight: .regular, design: .rounded)
    static let numberFont = Font.system(size: 48, weight: .bold, design: .rounded)
    static let mediumNumberFont = Font.system(size: 32, weight: .bold, design: .rounded)
    
    // MARK: - Card Styling
    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 10
    static let cardPadding: CGFloat = 20
    
    // MARK: - Helper Functions
    static func statusColor(for amount: Double, threshold: Double = 0) -> Color {
        amount >= threshold ? primaryGreen : primaryRed
    }
    
    static func statusGradient(for amount: Double, threshold: Double = 0) -> LinearGradient {
        amount >= threshold ? greenGradient : redGradient
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    var backgroundColor: Color = Theme.cardBackground
    
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(backgroundColor)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: .black.opacity(0.2), radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(.ultraThinMaterial)
            .cornerRadius(Theme.cardCornerRadius)
    }
}

extension View {
    func cardStyle(backgroundColor: Color = Theme.cardBackground) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor))
    }
    
    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.greenGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headlineFont)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headlineFont)
            .foregroundColor(Theme.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.primaryBlue.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
