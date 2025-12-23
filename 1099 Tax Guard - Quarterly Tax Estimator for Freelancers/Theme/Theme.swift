//
//  Theme.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI

// MARK: - App Theme
// MARK: - App Theme
struct Theme {
    // MARK: - Electric Blue Palette
    
    // Main Background
    static let electricBlue = Color.black // Pivoting to Midnight Theme
    static let deepBlue = Color(hex: "1C1C1E") // Dark Gray for cards/shadows
    static let background = electricBlue
    
    // Accents
    static let neonLime = Color(hex: "D0FF00") // Slightly punchier lime for black bg
    static let pureWhite = Color.white
    static let semiWhite = Color.white.opacity(0.9)
    static let softWhite = Color.white.opacity(0.6)
    
    // Semantic Colors
    static let primaryGreen = neonLime // Mapping legacy name to new color
    static let primaryRed = Color(hex: "FF453A") // Standard iOS Red for errors
    static let primaryBlue = Color(hex: "6BF5FF") // Cyan accent
    
    static let textPrimary = pureWhite
    static let textSecondary = softWhite
    static let textMuted = Color.white.opacity(0.4)
    static let textDark = Color(hex: "1A1A1A") // For text on Lime buttons
    
    // Card Backgrounds
    static let cardBackground = Color.white.opacity(0.1)
    static let cardBackgroundLight = Color.white.opacity(0.15)
    
    // MARK: - Typography (SF Pro, Bold)
    
    static let largeTitleFont = Font.system(size: 34, weight: .heavy, design: .default)
    static let titleFont = Font.system(size: 28, weight: .bold, design: .default)
    static let headlineFont = Font.system(size: 20, weight: .bold, design: .default)
    static let subheadlineFont = Font.system(size: 17, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 13, weight: .medium, design: .default)
    
    static let numberFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let mediumNumberFont = Font.system(size: 24, weight: .bold, design: .rounded)
    
    // MARK: - Gradients (Electric Blue)
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [electricBlue, deepBlue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let limeGradient = LinearGradient(
        gradient: Gradient(colors: [neonLime, Color(hex: "C8DE40")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "6BF5FF"), Color(hex: "4136F1")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "FFD60A"), Color(hex: "FF9F0A")]), // Gold to Orange
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Compatibility / Additional Accents
    static let accentGold = Color(hex: "FFD60A")
    static let accentPurple = Color(hex: "BF5AF2")
    
    static let greenGradient = limeGradient // Alias
    static let redGradient = LinearGradient(
        gradient: Gradient(colors: [primaryRed, Color(hex: "FF3B30")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Dimensions
    
    static let cardCornerRadius: CGFloat = 24 // Increased for "Squircle" look
    static let cardShadowRadius: CGFloat = 8
}

// MARK: - Modifiers

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.limeGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headlineFont)
            .foregroundColor(Theme.textDark) // Dark text on Lime
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.neonLime) // Solid color over gradient for sharper loom
            .cornerRadius(Theme.cardCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .shadow(color: Theme.neonLime.opacity(0.3), radius: 8, x: 0, y: 4)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headlineFont)
            .foregroundColor(Theme.pureWhite)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.15))
            .cornerRadius(Theme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

// Extension to support Hex colors
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// Extensions for consistency
extension View {
    func glassCardStyle() -> some View {
        modifier(GlassCardModifier())
    }
    
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
