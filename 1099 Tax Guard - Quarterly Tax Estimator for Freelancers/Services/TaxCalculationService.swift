//
//  TaxCalculationService.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation
import Combine

class TaxCalculationService: ObservableObject {
    static let shared = TaxCalculationService()
    
    // MARK: - Published Properties
    @Published var totalIncome: Double = 0
    @Published var totalDeductions: Double = 0
    @Published var netIncome: Double = 0
    @Published var selfEmploymentTax: Double = 0
    @Published var federalTax: Double = 0
    @Published var stateTax: Double = 0
    @Published var totalTaxOwed: Double = 0
    @Published var quarterlyPayment: Double = 0
    @Published var amountToSetAside: Double = 0
    
    // MARK: - Tax Breakdown
    struct TaxBreakdown {
        let grossIncome: Double
        let totalDeductions: Double
        let netIncome: Double
        let selfEmploymentTax: (socialSecurity: Double, medicare: Double, total: Double)
        let federalIncomeTax: Double
        let stateTax: Double
        let totalTaxOwed: Double
        let effectiveFederalRate: Double
        let effectiveTotalRate: Double
        let quarterlyPayment: Double
        let amountToSetAsideNow: Double
        
        var formattedSummary: String {
            return """
            Gross Income: $\(String(format: "%.2f", grossIncome))
            Deductions: -$\(String(format: "%.2f", totalDeductions))
            Net Income: $\(String(format: "%.2f", netIncome))
            
            Self-Employment Tax: $\(String(format: "%.2f", selfEmploymentTax.total))
            Federal Income Tax: $\(String(format: "%.2f", federalIncomeTax))
            State Tax: $\(String(format: "%.2f", stateTax))
            
            Total Tax Owed: $\(String(format: "%.2f", totalTaxOwed))
            Effective Rate: \(String(format: "%.1f", effectiveTotalRate * 100))%
            """
        }
    }
    
    // MARK: - Calculate Taxes
    func calculateTaxes(
        grossIncome: Double,
        deductions: Double,
        state: USState,
        filingStatus: FilingStatus
    ) -> TaxBreakdown {
        // Step 1: Calculate net self-employment income
        let netSelfEmploymentIncome = max(0, grossIncome - deductions)
        
        // Step 2: Calculate self-employment tax
        let seTax = SelfEmploymentTax.calculate(on: netSelfEmploymentIncome)
        
        // Step 3: Calculate deductible portion of SE tax (employer-equivalent = 50%)
        let seTaxDeduction = SelfEmploymentTax.deductiblePortion(of: seTax.total)
        
        // Step 4: Calculate adjusted gross income (AGI)
        let agi = netSelfEmploymentIncome - seTaxDeduction
        
        // Step 5: Apply standard deduction for federal tax
        let standardDeduction = FederalTaxBrackets.standardDeduction(for: filingStatus)
        let federalTaxableIncome = max(0, agi - standardDeduction)
        
        // Step 6: Calculate federal income tax
        let federalTax = FederalTaxBrackets.calculateTax(on: federalTaxableIncome, filingStatus: filingStatus)
        
        // Step 7: Calculate state tax
        let stateTax = state.calculateTax(on: netSelfEmploymentIncome)
        
        // Step 8: Calculate total tax
        let totalTax = seTax.total + federalTax + stateTax
        
        // Step 9: Calculate quarterly payment
        let quarterlyPayment = totalTax / 4
        
        // Step 10: Calculate effective rates
        let effectiveFederalRate = grossIncome > 0 ? federalTax / grossIncome : 0
        let effectiveTotalRate = grossIncome > 0 ? totalTax / grossIncome : 0
        
        // Step 11: Calculate amount to set aside now (percentage of income)
        let setAsidePercentage = grossIncome > 0 ? totalTax / grossIncome : 0.30 // Default 30%
        let amountToSetAside = grossIncome * setAsidePercentage
        
        // Update published properties
        self.totalIncome = grossIncome
        self.totalDeductions = deductions
        self.netIncome = netSelfEmploymentIncome
        self.selfEmploymentTax = seTax.total
        self.federalTax = federalTax
        self.stateTax = stateTax
        self.totalTaxOwed = totalTax
        self.quarterlyPayment = quarterlyPayment
        self.amountToSetAside = amountToSetAside
        
        return TaxBreakdown(
            grossIncome: grossIncome,
            totalDeductions: deductions,
            netIncome: netSelfEmploymentIncome,
            selfEmploymentTax: seTax,
            federalIncomeTax: federalTax,
            stateTax: stateTax,
            totalTaxOwed: totalTax,
            effectiveFederalRate: effectiveFederalRate,
            effectiveTotalRate: effectiveTotalRate,
            quarterlyPayment: quarterlyPayment,
            amountToSetAsideNow: amountToSetAside
        )
    }
    
    // MARK: - Calculate for Current Quarter
    func calculateCurrentQuarterTaxes(
        incomes: [Income],
        deductions: [Deduction],
        state: USState,
        filingStatus: FilingStatus
    ) -> TaxBreakdown {
        let totalIncome = incomes.reduce(0) { $0 + $1.amount }
        let totalDeductions = deductions.reduce(0) { $0 + $1.amount }
        
        return calculateTaxes(
            grossIncome: totalIncome,
            deductions: totalDeductions,
            state: state,
            filingStatus: filingStatus
        )
    }
    
    // MARK: - Annualized Estimate
    func calculateAnnualizedEstimate(
        ytdIncome: Double,
        ytdDeductions: Double,
        state: USState,
        filingStatus: FilingStatus
    ) -> TaxBreakdown {
        // Project annual income based on YTD
        let currentQuarter = QuarterHelper.currentQuarter()
        let annualizationFactor = 4.0 / Double(currentQuarter)
        
        let projectedAnnualIncome = ytdIncome * annualizationFactor
        let projectedAnnualDeductions = ytdDeductions * annualizationFactor
        
        return calculateTaxes(
            grossIncome: projectedAnnualIncome,
            deductions: projectedAnnualDeductions,
            state: state,
            filingStatus: filingStatus
        )
    }
    
    // MARK: - Set Aside Recommendation
    func recommendedSetAsidePercentage(for expectedIncome: Double, state: USState, filingStatus: FilingStatus) -> Double {
        let breakdown = calculateTaxes(
            grossIncome: expectedIncome,
            deductions: 0, // Assume no deductions for conservative estimate
            state: state,
            filingStatus: filingStatus
        )
        
        return breakdown.effectiveTotalRate
    }
    
    // MARK: - Mileage Calculation
    func calculateMileageDeduction(miles: Double) -> Double {
        return miles * DeductionCategory.mileageRatePerMile
    }
}

// MARK: - Currency Formatting
extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    var percentFormatted: String {
        return String(format: "%.1f%%", self * 100)
    }
    
    var wholeNumberFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }
}
