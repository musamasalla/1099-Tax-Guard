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
        NavigationView {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with greeting
                        headerSection
                        
                        // Main cards
                        VStack(spacing: 16) {
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
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
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
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text("\(currentYear) Tax Dashboard")
                    .font(Theme.titleFont)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.premiumGradient)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    // MARK: - Income Card
    private var incomeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.primaryGreen)
                Text(QuarterHelper.quarterName(currentQuarter))
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: IncomeListView()) {
                    Text("View All")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                }
            }
            
            Text("Current Quarter Income")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            Text(quarterlyIncome.currencyFormatted)
                .font(Theme.numberFont)
                .foregroundColor(Theme.primaryGreen)
            
            // YTD indicator
            HStack {
                Text("YTD Total:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(ytdIncome.currencyFormatted)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Tax Owed Card
    private var taxOwedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(taxBreakdown.totalTaxOwed > 0 ? Theme.primaryRed : Theme.primaryGreen)
                Text("Amount to Set Aside")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: TaxCalculatorView()) {
                    Text("Details")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                }
            }
            
            Text("Estimated Tax Owed")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            Text(taxBreakdown.totalTaxOwed.currencyFormatted)
                .font(Theme.numberFont)
                .foregroundColor(taxBreakdown.totalTaxOwed > 0 ? Theme.primaryRed : Theme.primaryGreen)
            
            // Breakdown
            HStack(spacing: 16) {
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
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(taxBreakdown.totalTaxOwed > 1000 ? Theme.primaryRed.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Next Payment Card
    private var nextPaymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(Theme.accentGold)
                Text("Quarterly Payment")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                
                NavigationLink(destination: PaymentsView()) {
                    Text("Manage")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.primaryBlue)
                }
            }
            
            Text("Next Payment Due")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("Q\(nextPayment.quarter)")
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.accentGold)
                
                let daysUntil = QuarterHelper.daysUntil(date: nextPayment.date)
                Text(daysUntil > 0 ? "in \(daysUntil) days" : "Today!")
                    .font(Theme.headlineFont)
                    .foregroundColor(daysUntil <= 7 ? Theme.primaryRed : Theme.textSecondary)
                    .padding(.bottom, 8)
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
                Text("Suggested Payment:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                Text(taxBreakdown.quarterlyPayment.currencyFormatted)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.primaryGreen)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(icon: "plus.circle.fill", title: "Add Income", color: Theme.primaryGreen) {
                        showAddIncome = true
                    }
                    
                    QuickActionButton(icon: "minus.circle.fill", title: "Add Deduction", color: Theme.primaryBlue) {
                        showAddDeduction = true
                    }
                    
                    QuickActionButton(icon: "car.fill", title: "Log Mileage", color: Theme.accentPurple) {
                        showAddDeduction = true
                    }
                    
                    NavigationLink(destination: PaymentsView()) {
                        QuickActionContent(icon: "creditcard.fill", title: "Pay Taxes", color: Theme.accentGold)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(Array(allIncomes.prefix(3)), id: \.id) { income in
                    RecentActivityRow(
                        icon: "arrow.down.circle.fill",
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
                        icon: "arrow.up.circle.fill",
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
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
            Text(amount.wholeNumberFormatted)
                .font(Theme.captionFont)
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
    }
}

struct QuickActionContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(width: 100, height: 80)
        .background(Theme.cardBackground)
        .cornerRadius(12)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(Theme.bodyFont)
                    .foregroundColor(amountColor)
                Text(date, style: .date)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
