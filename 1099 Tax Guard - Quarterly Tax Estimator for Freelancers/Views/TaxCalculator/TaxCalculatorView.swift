//
//  TaxCalculatorView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct TaxCalculatorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taxService = TaxCalculationService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Income.date, ascending: false)],
        animation: .default
    )
    private var allIncomes: FetchedResults<Income>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deduction.date, ascending: false)],
        animation: .default
    )
    private var allDeductions: FetchedResults<Deduction>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.id, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var showBreakdown = true
    
    private var currentYear: Int { QuarterHelper.currentYear() }
    
    private var ytdIncome: Double {
        let startOfYear = Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        return allIncomes
            .filter { $0.date ?? Date() >= startOfYear }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var ytdDeductions: Double {
        let startOfYear = Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        return allDeductions
            .filter { $0.date ?? Date() >= startOfYear }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var settings: UserSettings? { userSettings.first }
    
    private var userState: USState {
        guard let stateRaw = settings?.state else { return .california }
        return USState(rawValue: stateRaw) ?? .california
    }
    
    private var filingStatus: FilingStatus {
        guard let statusRaw = settings?.filingStatus else { return .single }
        return FilingStatus(rawValue: statusRaw) ?? .single
    }
    
    private var taxBreakdown: TaxCalculationService.TaxBreakdown {
        taxService.calculateTaxes(
            grossIncome: ytdIncome,
            deductions: ytdDeductions,
            state: userState,
            filingStatus: filingStatus
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount to Set Aside - PROMINENT
                setAsideCard
                
                // Income & Deductions summary
                incomeDeductionsSummary
                
                // Tax breakdown
                taxBreakdownSection
                
                // Quarterly due dates
                quarterlyDueDates
                
                // Effective rate & tips
                taxTipsCard
            }
            .padding()
            .padding(.bottom, 90) // Account for capsule tab bar
        }
        .navigationTitle("Tax Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Set Aside Card (PROMINENT)
    private var setAsideCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.accentGold)
                Text("AMOUNT TO SET ASIDE NOW")
                    .font(Theme.captionFont.bold())
                    .foregroundColor(Theme.accentGold)
                Spacer()
            }
            
            Text(taxBreakdown.totalTaxOwed.currencyFormatted)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(taxBreakdown.totalTaxOwed > 0 ? Theme.primaryRed : Theme.primaryGreen)
            
            Text("Estimated total tax for \(currentYear)")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
            
            Divider()
                .background(Theme.cardBackgroundLight)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per Quarter")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text(taxBreakdown.quarterlyPayment.currencyFormatted)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Effective Rate")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text(taxBreakdown.effectiveTotalRate.percentFormatted)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
        .padding(24)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(taxBreakdown.totalTaxOwed > 1000 ? Theme.primaryRed.opacity(0.5) : Theme.primaryGreen.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Income & Deductions Summary
    private var incomeDeductionsSummary: some View {
        HStack(spacing: 16) {
            // Income
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Theme.primaryGreen)
                    Text("YTD Income")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
                Text(ytdIncome.currencyFormatted)
                    .font(Theme.mediumNumberFont)
                    .foregroundColor(Theme.primaryGreen)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
            
            // Deductions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Theme.primaryBlue)
                    Text("Deductions")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
                Text(ytdDeductions.currencyFormatted)
                    .font(Theme.mediumNumberFont)
                    .foregroundColor(Theme.primaryBlue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Tax Breakdown Section
    private var taxBreakdownSection: some View {
        VStack(spacing: 16) {
            Button(action: { withAnimation { showBreakdown.toggle() } }) {
                HStack {
                    Text("Tax Breakdown")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            if showBreakdown {
                VStack(spacing: 12) {
                    // Net Income
                    TaxLineItem(
                        label: "Net Self-Employment Income",
                        amount: taxBreakdown.netIncome,
                        isSubtotal: true
                    )
                    
                    Divider().background(Theme.cardBackgroundLight)
                    
                    // Self-Employment Tax
                    VStack(spacing: 8) {
                        TaxLineItem(
                            label: "Self-Employment Tax (15.3%)",
                            amount: taxBreakdown.selfEmploymentTax.total,
                            color: Theme.primaryRed
                        )
                        
                        HStack {
                            Text("Social Security (12.4%)")
                                .font(.caption2)
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text(taxBreakdown.selfEmploymentTax.socialSecurity.currencyFormatted)
                                .font(.caption2)
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.leading, 16)
                        
                        HStack {
                            Text("Medicare (2.9%)")
                                .font(.caption2)
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text(taxBreakdown.selfEmploymentTax.medicare.currencyFormatted)
                                .font(.caption2)
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.leading, 16)
                    }
                    
                    Divider().background(Theme.cardBackgroundLight)
                    
                    // Federal Income Tax
                    TaxLineItem(
                        label: "Federal Income Tax",
                        amount: taxBreakdown.federalIncomeTax,
                        color: Theme.primaryRed
                    )
                    
                    HStack {
                        Text("Filing: \(filingStatus.displayName)")
                            .font(.caption2)
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                        Text("Bracket: \(FederalTaxBrackets.marginalRate(for: taxBreakdown.netIncome, filingStatus: filingStatus).percentFormatted)")
                            .font(.caption2)
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(.leading, 16)
                    
                    Divider().background(Theme.cardBackgroundLight)
                    
                    // State Tax
                    TaxLineItem(
                        label: "State Tax (\(userState.fullName))",
                        amount: taxBreakdown.stateTax,
                        color: userState.hasNoIncomeTax ? Theme.primaryGreen : Theme.primaryRed
                    )
                    
                    if userState.hasNoIncomeTax {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.primaryGreen)
                                .font(.caption)
                            Text("No state income tax!")
                                .font(.caption2)
                                .foregroundColor(Theme.primaryGreen)
                            Spacer()
                        }
                        .padding(.leading, 16)
                    }
                    
                    Divider().background(Theme.cardBackgroundLight)
                    
                    // Total
                    TaxLineItem(
                        label: "TOTAL TAX OWED",
                        amount: taxBreakdown.totalTaxOwed,
                        isTotal: true,
                        color: Theme.primaryRed
                    )
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Quarterly Due Dates
    private var quarterlyDueDates: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quarterly Due Dates")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(1...4, id: \.self) { quarter in
                    let dueDate = QuarterHelper.dueDate(for: quarter, year: currentYear)
                    let isPast = dueDate < Date()
                    let isNext = QuarterHelper.nextDueDate().quarter == quarter && QuarterHelper.nextDueDate().year == currentYear
                    
                    HStack {
                        Circle()
                            .fill(isPast ? Theme.primaryGreen : (isNext ? Theme.accentGold : Theme.textMuted))
                            .frame(width: 8, height: 8)
                        
                        Text("Q\(quarter)")
                            .font(Theme.bodyFont)
                            .foregroundColor(isNext ? Theme.accentGold : Theme.textPrimary)
                        
                        Spacer()
                        
                        Text(dueDate, style: .date)
                            .font(Theme.captionFont)
                            .foregroundColor(isPast ? Theme.textMuted : Theme.textSecondary)
                        
                        Text(taxBreakdown.quarterlyPayment.wholeNumberFormatted)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 80, alignment: .trailing)
                        
                        if isPast {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.primaryGreen)
                                .font(.caption)
                        } else if isNext {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(Theme.accentGold)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(isNext ? Theme.accentGold.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Tax Tips Card
    private var taxTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Theme.accentGold)
                Text("Tax Tips")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(text: "Set aside \(taxBreakdown.effectiveTotalRate.percentFormatted) of every payment for taxes")
                TipRow(text: "Track all business mileage at $0.67/mile")
                TipRow(text: "Don't forget home office deduction if applicable")
                TipRow(text: "Pay quarterly to avoid penalties")
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views
struct TaxLineItem: View {
    let label: String
    let amount: Double
    var isSubtotal: Bool = false
    var isTotal: Bool = false
    var color: Color = Theme.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? Theme.headlineFont : Theme.bodyFont)
                .foregroundColor(isTotal ? Theme.textPrimary : Theme.textSecondary)
            
            Spacer()
            
            Text(amount.currencyFormatted)
                .font(isTotal ? Theme.headlineFont : Theme.bodyFont)
                .foregroundColor(isTotal || isSubtotal ? color : Theme.textPrimary)
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(Theme.primaryGreen)
                .font(.caption)
            
            Text(text)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationView {
        TaxCalculatorView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
