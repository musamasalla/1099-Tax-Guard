//
//  FederalTaxBrackets.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation

// MARK: - Filing Status
enum FilingStatus: String, CaseIterable, Codable {
    case single = "Single"
    case marriedFilingJointly = "Married Filing Jointly"
    case marriedFilingSeparately = "Married Filing Separately"
    case headOfHousehold = "Head of Household"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .single:
            return "person.fill"
        case .marriedFilingJointly:
            return "person.2.fill"
        case .marriedFilingSeparately:
            return "person.fill.turn.down"
        case .headOfHousehold:
            return "house.fill"
        }
    }
}

// MARK: - Tax Bracket
struct TaxBracket {
    let minIncome: Double
    let maxIncome: Double
    let rate: Double
}

// MARK: - Federal Tax Brackets 2025
struct FederalTaxBrackets {
    
    // 2025 Federal Tax Brackets (projected/estimated based on inflation adjustments)
    static func brackets(for filingStatus: FilingStatus) -> [TaxBracket] {
        switch filingStatus {
        case .single:
            return [
                TaxBracket(minIncome: 0, maxIncome: 11_925, rate: 0.10),
                TaxBracket(minIncome: 11_925, maxIncome: 48_475, rate: 0.12),
                TaxBracket(minIncome: 48_475, maxIncome: 103_350, rate: 0.22),
                TaxBracket(minIncome: 103_350, maxIncome: 197_300, rate: 0.24),
                TaxBracket(minIncome: 197_300, maxIncome: 250_525, rate: 0.32),
                TaxBracket(minIncome: 250_525, maxIncome: 626_350, rate: 0.35),
                TaxBracket(minIncome: 626_350, maxIncome: .infinity, rate: 0.37)
            ]
        case .marriedFilingJointly:
            return [
                TaxBracket(minIncome: 0, maxIncome: 23_850, rate: 0.10),
                TaxBracket(minIncome: 23_850, maxIncome: 96_950, rate: 0.12),
                TaxBracket(minIncome: 96_950, maxIncome: 206_700, rate: 0.22),
                TaxBracket(minIncome: 206_700, maxIncome: 394_600, rate: 0.24),
                TaxBracket(minIncome: 394_600, maxIncome: 501_050, rate: 0.32),
                TaxBracket(minIncome: 501_050, maxIncome: 751_600, rate: 0.35),
                TaxBracket(minIncome: 751_600, maxIncome: .infinity, rate: 0.37)
            ]
        case .marriedFilingSeparately:
            return [
                TaxBracket(minIncome: 0, maxIncome: 11_925, rate: 0.10),
                TaxBracket(minIncome: 11_925, maxIncome: 48_475, rate: 0.12),
                TaxBracket(minIncome: 48_475, maxIncome: 103_350, rate: 0.22),
                TaxBracket(minIncome: 103_350, maxIncome: 197_300, rate: 0.24),
                TaxBracket(minIncome: 197_300, maxIncome: 250_525, rate: 0.32),
                TaxBracket(minIncome: 250_525, maxIncome: 375_800, rate: 0.35),
                TaxBracket(minIncome: 375_800, maxIncome: .infinity, rate: 0.37)
            ]
        case .headOfHousehold:
            return [
                TaxBracket(minIncome: 0, maxIncome: 17_000, rate: 0.10),
                TaxBracket(minIncome: 17_000, maxIncome: 64_850, rate: 0.12),
                TaxBracket(minIncome: 64_850, maxIncome: 103_350, rate: 0.22),
                TaxBracket(minIncome: 103_350, maxIncome: 197_300, rate: 0.24),
                TaxBracket(minIncome: 197_300, maxIncome: 250_500, rate: 0.32),
                TaxBracket(minIncome: 250_500, maxIncome: 626_350, rate: 0.35),
                TaxBracket(minIncome: 626_350, maxIncome: .infinity, rate: 0.37)
            ]
        }
    }
    
    // Standard Deduction 2025
    static func standardDeduction(for filingStatus: FilingStatus) -> Double {
        switch filingStatus {
        case .single:
            return 15_000
        case .marriedFilingJointly:
            return 30_000
        case .marriedFilingSeparately:
            return 15_000
        case .headOfHousehold:
            return 22_500
        }
    }
    
    // Calculate federal income tax
    static func calculateTax(on taxableIncome: Double, filingStatus: FilingStatus) -> Double {
        let brackets = self.brackets(for: filingStatus)
        var totalTax: Double = 0
        var remainingIncome = taxableIncome
        
        for bracket in brackets {
            if remainingIncome <= 0 {
                break
            }
            
            let taxableInBracket = min(remainingIncome, bracket.maxIncome - bracket.minIncome)
            totalTax += taxableInBracket * bracket.rate
            remainingIncome -= taxableInBracket
        }
        
        return totalTax
    }
    
    // Get the marginal tax rate for a given income
    static func marginalRate(for taxableIncome: Double, filingStatus: FilingStatus) -> Double {
        let brackets = self.brackets(for: filingStatus)
        
        for bracket in brackets {
            if taxableIncome >= bracket.minIncome && taxableIncome < bracket.maxIncome {
                return bracket.rate
            }
        }
        
        // Return top rate if income exceeds all brackets
        return brackets.last?.rate ?? 0.37
    }
    
    // Get effective tax rate
    static func effectiveRate(for taxableIncome: Double, filingStatus: FilingStatus) -> Double {
        guard taxableIncome > 0 else { return 0 }
        let tax = calculateTax(on: taxableIncome, filingStatus: filingStatus)
        return tax / taxableIncome
    }
}

// MARK: - Self-Employment Tax
struct SelfEmploymentTax {
    // 2025 Self-Employment Tax Rates
    static let socialSecurityRate: Double = 0.124 // 12.4% (6.2% x 2)
    static let medicareRate: Double = 0.029 // 2.9% (1.45% x 2)
    static let combinedRate: Double = 0.153 // 15.3% total
    
    // Social Security wage base for 2025 (estimated)
    static let socialSecurityWageBase: Double = 176_100
    
    // Additional Medicare tax threshold and rate
    static let additionalMedicareThreshold: Double = 200_000 // Single
    static let additionalMedicareRate: Double = 0.009 // 0.9%
    
    // Calculate SE tax on net earnings
    // Only 92.35% of net self-employment income is subject to SE tax
    static let netEarningsFactor: Double = 0.9235
    
    static func calculate(on netSelfEmploymentIncome: Double) -> (socialSecurity: Double, medicare: Double, total: Double) {
        let netEarnings = netSelfEmploymentIncome * netEarningsFactor
        
        // Social Security portion (capped at wage base)
        let socialSecurityEarnings = min(netEarnings, socialSecurityWageBase)
        let socialSecurityTax = socialSecurityEarnings * socialSecurityRate
        
        // Medicare portion (no cap)
        var medicareTax = netEarnings * medicareRate
        
        // Additional Medicare tax on high earners
        if netEarnings > additionalMedicareThreshold {
            let additionalMedicareEarnings = netEarnings - additionalMedicareThreshold
            medicareTax += additionalMedicareEarnings * additionalMedicareRate
        }
        
        return (socialSecurityTax, medicareTax, socialSecurityTax + medicareTax)
    }
    
    // Deductible portion of SE tax (employer-equivalent portion = 50%)
    static func deductiblePortion(of seTax: Double) -> Double {
        return seTax * 0.5
    }
}
