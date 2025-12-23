//
//  DashboardView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taxService = TaxCalculationService.shared
    @StateObject var subscriptionService = SubscriptionService.shared
    
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
    
    @State private var showAddIncome = false
    @State private var showAddDeduction = false
    
    private var currentQuarter: Int { QuarterHelper.currentQuarter() }
    private var currentYear: Int { QuarterHelper.currentYear() }
    
    private var quarterlyIncome: Double {
        let range = QuarterHelper.dateRange(for: currentQuarter, year: currentYear)
        return allIncomes
            .filter { $0.date ?? Date() >= range.start && $0.date ?? Date() < range.end }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var quarterlyDeductions: Double {
        let range = QuarterHelper.dateRange(for: currentQuarter, year: currentYear)
        return allDeductions
            .filter { $0.date ?? Date() >= range.start && $0.date ?? Date() < range.end }
            .reduce(0) { $0 + $1.amount }
    }
    
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
    
    private var nextPayment: (quarter: Int, year: Int, date: Date) {
        QuarterHelper.nextDueDate()
    }
    
    var body: some View {
        ZStack {
            ElectricBackground()
                .ignoresSafeArea(edges: .top)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with greeting
                    headerSection
                    
                    // Main cards
                    VStack(spacing: 20) {
                        // Current Quarter Income Card
                        incomeCard
                        
                        // Estimated Tax Owed Card
                        taxOwedCard
                        
                        // Next Payment Due Card
                        nextPaymentCard
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding(.bottom, 90) // Account for capsule tab bar
            }
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView()
        }
        .sheet(isPresented: $showAddDeduction) {
            AddDeductionView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text("\(String(currentYear)) Dashboard")
                    .font(Theme.largeTitleFont)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
            
            // Premium badge if subscribed
            if subscriptionService.isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("PRO")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.premiumGradient)
                .cornerRadius(20)
                .shadow(color: Theme.accentPurple.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8) // Reduced to minimize top gap
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
    
    // MARK: - Income Card
    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.primaryGreen)
                    .font(.title3)
                Text(QuarterHelper.quarterName(currentQuarter))
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: IncomeListView()) {
                    Text("View All")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quarterly Income")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textMuted)
                
                Text(quarterlyIncome.currencyFormatted)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.textPrimary) // Cleaner look, not green
            }
            
            // YTD indicator
            HStack {
                Text("YTD Total:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(ytdIncome.currencyFormatted)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.top, 4)
        }
        .padding(24) // More padding for elegance
        .glassCardStyle()
    }
    
    // MARK: - Tax Owed Card
    private var taxOwedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundColor(taxBreakdown.totalTaxOwed > 0 ? Theme.primaryRed : Theme.primaryGreen)
                    .font(.title3)
                Text("Tax Est.")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: TaxCalculatorView()) {
                    Text("Details")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Set Aside")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textMuted)
                
                AnimatableNumber(value: taxBreakdown.totalTaxOwed, format: { $0.currencyFormatted })
                    .font(Theme.numberFont)
                    .foregroundColor(taxBreakdown.totalTaxOwed > 0 ? Theme.primaryRed : Theme.primaryGreen)
                    .contentTransition(.numericText())
            }
            
            Divider()
                .background(Theme.textMuted.opacity(0.2))
            
            // Breakdown
            HStack(spacing: 20) {
                TaxBreakdownItem(label: "SE Tax", amount: taxBreakdown.selfEmploymentTax.total)
                TaxBreakdownItem(label: "Federal", amount: taxBreakdown.federalIncomeTax)
                TaxBreakdownItem(label: "State", amount: taxBreakdown.stateTax)
            }
            
            // Effective rate
            HStack {
                Text("Effective Rate:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(taxBreakdown.effectiveTotalRate.percentFormatted)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .glassCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(taxBreakdown.totalTaxOwed > 1000 ? Theme.primaryRed.opacity(0.5) : Theme.primaryGreen.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: (taxBreakdown.totalTaxOwed > 1000 ? Theme.primaryRed : Theme.primaryGreen).opacity(0.3), radius: 20, x: 0, y: 0)
    }
    
    // MARK: - Next Payment Card
    private var nextPaymentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.accentGold)
                    .font(.title3)
                Text("Deadline")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: PaymentsView()) {
                    Text("Manage")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.primaryBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("Q\(nextPayment.quarter)")
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.accentGold)
                
                let daysUntil = QuarterHelper.daysUntil(date: nextPayment.date)
                Text(daysUntil > 0 ? "in \(daysUntil) days" : "Today!")
                    .font(Theme.titleFont) // Serif
                    .foregroundColor(daysUntil <= 7 ? Theme.primaryRed : Theme.textSecondary)
            }
            
            // Due date
            HStack {
                Text("Due Date:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(nextPayment.date, style: .date)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
            }
            
            // Suggested payment amount
            HStack {
                Text("Suggested:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(taxBreakdown.quarterlyPayment.currencyFormatted)
                    .font(Theme.captionFont) // Can be bold
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primaryGreen)
            }
        }
        .padding(24)
        .glassCardStyle()
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickActionButton(icon: "plus", title: "Income", color: Theme.primaryGreen) {
                        showAddIncome = true
                    }
                    
                    QuickActionButton(icon: "minus", title: "Deduction", color: Theme.primaryBlue) {
                        showAddDeduction = true
                    }
                    
                    QuickActionButton(icon: "steeringwheel", title: "Mileage", color: Theme.accentPurple) {
                        showAddDeduction = true
                    }
                    
                    NavigationLink(destination: PaymentsView()) {
                        QuickActionContent(icon: "checkmark.seal", title: "Pay Tax", color: Theme.accentGold)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(Array(allIncomes.prefix(3)), id: \.id) { income in
                    RecentActivityRow(
                        icon: "arrow.down.left",
                        iconColor: Theme.primaryGreen,
                        title: income.clientName ?? "Income",
                        subtitle: IncomeType(rawValue: income.incomeType ?? "")?.displayName ?? "",
                        amount: "+\(income.amount.currencyFormatted)",
                        amountColor: Theme.primaryGreen,
                        date: income.date ?? Date()
                    )
                }
                
                ForEach(Array(allDeductions.prefix(2)), id: \.id) { deduction in
                    RecentActivityRow(
                        icon: "arrow.up.right",
                        iconColor: Theme.primaryRed,
                        title: DeductionCategory(rawValue: deduction.category ?? "")?.displayName ?? "Deduction",
                        subtitle: "Deduction",
                        amount: "-\(deduction.amount.currencyFormatted)",
                        amountColor: Theme.primaryRed,
                        date: deduction.date ?? Date()
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views
struct TaxBreakdownItem: View {
    let label: String
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
            Text(amount.wholeNumberFormatted)
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionContent(icon: icon, title: title, color: color)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct QuickActionContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                )
            
            Text(title)
                .font(Theme.captionFont)
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(width: 100, height: 110)
        .glassCardStyle()
    }
}

struct RecentActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let amountColor: Color
    let date: Date
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Theme.cardBackgroundLight)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 20))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(Theme.headlineFont)
                    .foregroundColor(amountColor)
                Text(date, style: .date)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(16)
        .glassCardStyle()
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
