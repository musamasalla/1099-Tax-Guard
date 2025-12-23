//
//  YearEndSummaryView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct YearEndSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
        sortDescriptors: [NSSortDescriptor(keyPath: \TaxPayment.quarter, ascending: true)],
        animation: .default
    )
    private var allPayments: FetchedResults<TaxPayment>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.id, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var selectedYear: Int = QuarterHelper.currentYear()
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    private var incomeByQuarter: [Int: Double] {
        var result: [Int: Double] = [:]
        for quarter in 1...4 {
            let range = QuarterHelper.dateRange(for: quarter, year: selectedYear)
            result[quarter] = allIncomes
                .filter { ($0.date ?? Date()) >= range.start && ($0.date ?? Date()) < range.end }
                .reduce(0) { $0 + $1.amount }
        }
        return result
    }
    
    private var totalIncome: Double {
        incomeByQuarter.values.reduce(0, +)
    }
    
    private var deductionsByCategory: [DeductionCategory: Double] {
        let startOfYear = Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let endOfYear = Calendar.current.date(from: DateComponents(year: selectedYear + 1, month: 1, day: 1))!
        
        var result: [DeductionCategory: Double] = [:]
        for deduction in allDeductions {
            guard let date = deduction.date, date >= startOfYear && date < endOfYear else { continue }
            if let catRaw = deduction.category, let category = DeductionCategory(rawValue: catRaw) {
                result[category, default: 0] += deduction.amount
            }
        }
        return result
    }
    
    private var totalDeductions: Double {
        deductionsByCategory.values.reduce(0, +)
    }
    
    private var yearPayments: [TaxPayment] {
        allPayments.filter { $0.year == selectedYear }
    }
    
    private var totalPaid: Double {
        yearPayments.filter { $0.confirmed }.reduce(0) { $0 + $1.amount }
    }
    
    private var userState: USState {
        guard let stateRaw = userSettings.first?.state else { return .california }
        return USState(rawValue: stateRaw) ?? .california
    }
    
    private var filingStatus: FilingStatus {
        guard let statusRaw = userSettings.first?.filingStatus else { return .single }
        return FilingStatus(rawValue: statusRaw) ?? .single
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Year selector
                    yearSelector
                    
                    // Summary cards
                    summaryCards
                    
                    // Income by quarter
                    incomeByQuarterSection
                    
                    // Deductions by category
                    deductionsByCategorySection
                    
                    // Tax payments
                    taxPaymentsSection
                    
                    // Export button
                    exportSection
                }
                .padding()
            }
        }
        .navigationTitle("Year-End Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Year Selector
    private var yearSelector: some View {
        HStack(spacing: 16) {
            Button(action: { selectedYear -= 1 }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.textSecondary)
            }
            
            Text("\(selectedYear)")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)
            
            Button(action: { selectedYear += 1 }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(selectedYear >= QuarterHelper.currentYear() ? Theme.textMuted : Theme.textSecondary)
            }
            .disabled(selectedYear >= QuarterHelper.currentYear())
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total Income",
                amount: totalIncome,
                color: Theme.primaryGreen
            )
            
            SummaryCard(
                title: "Deductions",
                amount: totalDeductions,
                color: Theme.primaryBlue
            )
            
            SummaryCard(
                title: "Tax Paid",
                amount: totalPaid,
                color: Theme.accentGold
            )
        }
    }
    
    // MARK: - Income by Quarter Section
    private var incomeByQuarterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income by Quarter")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(1...4, id: \.self) { quarter in
                    let amount = incomeByQuarter[quarter] ?? 0
                    let percentage = totalIncome > 0 ? amount / totalIncome : 0
                    
                    HStack {
                        Text("Q\(quarter)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 40, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Theme.cardBackgroundLight)
                                    .frame(height: 20)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Theme.primaryGreen)
                                    .frame(width: geometry.size.width * percentage, height: 20)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 20)
                        
                        Text(amount.wholeNumberFormatted)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Deductions by Category Section
    private var deductionsByCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deductions by Category")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            if deductionsByCategory.isEmpty {
                Text("No deductions recorded")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(deductionsByCategory.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 24)
                            
                            Text(category.displayName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Text(amount.currencyFormatted)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.primaryBlue)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Tax Payments Section
    private var taxPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quarterly Tax Payments")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(1...4, id: \.self) { quarter in
                    let payment = yearPayments.first { $0.quarter == quarter }
                    let isPaid = payment?.confirmed ?? false
                    
                    HStack {
                        Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isPaid ? Theme.primaryGreen : Theme.textMuted)
                        
                        Text("Q\(quarter)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        if let payment = payment, isPaid {
                            Text(payment.amount.currencyFormatted)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.primaryGreen)
                        } else {
                            Text("Not paid")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Divider().background(Theme.cardBackgroundLight)
                
                HStack {
                    Text("Total Paid")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text(totalPaid.currencyFormatted)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.primaryGreen)
                }
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(spacing: 12) {
            Button(action: exportPDF) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Export PDF for Tax Preparer")
                }
            }
            .buttonStyle(PrimaryButtonStyle(gradient: Theme.premiumGradient))
            
            if !subscriptionService.isPremium {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Theme.accentPurple)
                    Text("Premium feature")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
    }
    
    // MARK: - Export PDF
    private func exportPDF() {
        if !subscriptionService.isPremium {
            showPaywall = true
            return
        }
        
        if let pdfData = PDFExportService.shared.generateYearEndSummary(
            year: selectedYear,
            incomeByQuarter: incomeByQuarter,
            deductionsByCategory: deductionsByCategory,
            taxPayments: Array(yearPayments),
            userState: userState,
            filingStatus: filingStatus
        ) {
            if let url = PDFExportService.shared.savePDF(data: pdfData, fileName: "TaxGuard_\(selectedYear)_Summary") {
                pdfURL = url
                showShareSheet = true
            }
        }
    }
}

// MARK: - Supporting Views
struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
            
            Text(amount.wholeNumberFormatted)
                .font(Theme.headlineFont)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        YearEndSummaryView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
