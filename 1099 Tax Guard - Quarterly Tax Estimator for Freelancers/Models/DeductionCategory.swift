//
//  DeductionCategory.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation
import SwiftUI

enum DeductionCategory: String, CaseIterable, Codable {
    case mileage = "Mileage"
    case homeOffice = "Home Office"
    case equipment = "Equipment"
    case software = "Software"
    case healthInsurance = "Health Insurance"
    case officeSupplies = "Office Supplies"
    case professionalServices = "Professional Services"
    case travel = "Travel"
    case meals = "Meals (50%)"
    case education = "Education"
    case marketing = "Marketing"
    case utilities = "Utilities"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .mileage:
            return "car.fill"
        case .homeOffice:
            return "house.fill"
        case .equipment:
            return "desktopcomputer"
        case .software:
            return "app.badge.fill"
        case .healthInsurance:
            return "heart.fill"
        case .officeSupplies:
            return "paperclip"
        case .professionalServices:
            return "person.2.fill"
        case .travel:
            return "airplane"
        case .meals:
            return "fork.knife"
        case .education:
            return "book.fill"
        case .marketing:
            return "megaphone.fill"
        case .utilities:
            return "bolt.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .mileage:
            return Color(hex: "3B82F6") // Blue
        case .homeOffice:
            return Color(hex: "8B5CF6") // Purple
        case .equipment:
            return Color(hex: "EC4899") // Pink
        case .software:
            return Color(hex: "10B981") // Green
        case .healthInsurance:
            return Color(hex: "EF4444") // Red
        case .officeSupplies:
            return Color(hex: "F59E0B") // Amber
        case .professionalServices:
            return Color(hex: "6366F1") // Indigo
        case .travel:
            return Color(hex: "14B8A6") // Teal
        case .meals:
            return Color(hex: "F97316") // Orange
        case .education:
            return Color(hex: "06B6D4") // Cyan
        case .marketing:
            return Color(hex: "A855F7") // Violet
        case .utilities:
            return Color(hex: "84CC16") // Lime
        case .other:
            return Color(hex: "64748B") // Slate
        }
    }
    
    var description: String {
        switch self {
        case .mileage:
            return "Business miles driven at $0.67/mile (2025 IRS rate)"
        case .homeOffice:
            return "Dedicated home office space expenses"
        case .equipment:
            return "Computers, phones, cameras, tools"
        case .software:
            return "Apps, subscriptions, cloud services"
        case .healthInsurance:
            return "Self-employed health insurance premiums"
        case .officeSupplies:
            return "Paper, pens, desk supplies"
        case .professionalServices:
            return "Accountant, lawyer, consultant fees"
        case .travel:
            return "Business travel, lodging, transport"
        case .meals:
            return "Business meals (50% deductible)"
        case .education:
            return "Courses, training, certifications"
        case .marketing:
            return "Advertising, website, business cards"
        case .utilities:
            return "Phone, internet (business portion)"
        case .other:
            return "Other business expenses"
        }
    }
    
    // 2025 IRS mileage rate
    static let mileageRatePerMile: Double = 0.67
    
    // Categories that require premium subscription
    static var premiumCategories: [DeductionCategory] {
        return [.professionalServices, .travel, .meals, .education, .marketing, .utilities]
    }
    
    var isPremium: Bool {
        return DeductionCategory.premiumCategories.contains(self)
    }
}
