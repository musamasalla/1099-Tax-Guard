//
//  PaymentsView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct PaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var taxService = TaxCalculationService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaxPayment.year, ascending: false),
                         NSSortDescriptor(keyPath: \TaxPayment.quarter, ascending: false)],
        animation: .default
    )
    private var payments: FetchedResults<TaxPayment>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Income.date, ascending: false)],
        animation: .default
    )
    private var incomes: FetchedResults<Income>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deduction.date, ascending: false)],
        animation: .default
    )
    private var deductions: FetchedResults<Deduction>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.id, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var showPaymentSheet = false
    @State private var selectedQuarter: Int = 1
    
    private var currentYear: Int { QuarterHelper.currentYear() }
    
    private var ytdIncome: Double {
        let startOfYear = Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        return incomes.filter { $0.date ?? Date() >= startOfYear }.reduce(0) { $0 + $1.amount }
    }
    
    private var ytdDeductions: Double {
        let startOfYear = Calendar.current.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        return deductions.filter { $0.date ?? Date() >= startOfYear }.reduce(0) { $0 + $1.amount }
    }
    
    private var userState: USState {
        guard let stateRaw = userSettings.first?.state else { return .california }
        return USState(rawValue: stateRaw) ?? .california
    }
    
    private var filingStatus: FilingStatus {
        guard let statusRaw = userSettings.first?.filingStatus else { return .single }
        return FilingStatus(rawValue: statusRaw) ?? .single
    }
    
    private var suggestedPayment: Double {
        taxService.calculateTaxes(
            grossIncome: ytdIncome,
            deductions: ytdDeductions,
            state: userState,
            filingStatus: filingStatus
        ).quarterlyPayment
    }
    
    private var nextPayment: (quarter: Int, year: Int, date: Date) {
        QuarterHelper.nextDueDate()
    }
    
    private var totalPaidThisYear: Double {
        payments.filter { $0.year == currentYear && $0.confirmed }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Next payment header
                    nextPaymentHeader
                    
                    // Quick pay button
                    payNowSection
                    
                    // Quarterly payment cards
                    quarterlyPaymentsSection
                    
                    // Payment history
                    paymentHistorySection
                }
                .padding()
            }
        }
        .navigationTitle("Payments")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaymentSheet) {
            RecordPaymentSheet(quarter: selectedQuarter, year: currentYear, suggestedAmount: suggestedPayment)
        }
    }
    
    // MARK: - Next Payment Header
    private var nextPaymentHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Payment Due")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                    
                    Text("Q\(nextPayment.quarter) \(nextPayment.year)")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                let daysUntil = QuarterHelper.daysUntil(date: nextPayment.date)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(daysUntil > 0 ? "\(daysUntil)" : "Due!")
                        .font(Theme.numberFont)
                        .foregroundColor(daysUntil <= 7 ? Theme.primaryRed : Theme.accentGold)
                    Text(daysUntil > 0 ? "days left" : "Today")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Divider().background(Theme.cardBackgroundLight)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Amount")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text(suggestedPayment.currencyFormatted)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.primaryGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("YTD Paid")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                    Text(totalPaidThisYear.currencyFormatted)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Pay Now Section
    private var payNowSection: some View {
        VStack(spacing: 12) {
            // IRS Direct Pay link
            Link(destination: URL(string: "https://www.irs.gov/payments/direct-pay")!) {
                HStack {
                    Image(systemName: "link")
                    Text("Pay via IRS Direct Pay")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .font(Theme.headlineFont)
                .foregroundColor(.white)
                .padding()
                .background(Theme.blueGradient)
                .cornerRadius(12)
            }
            
            // Record payment button
            Button(action: {
                selectedQuarter = nextPayment.quarter
                showPaymentSheet = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Record Payment Made")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
    
    // MARK: - Quarterly Payments Section
    private var quarterlyPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(currentYear) Quarterly Payments")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(1...4, id: \.self) { quarter in
                    let dueDate = QuarterHelper.dueDate(for: quarter, year: currentYear)
                    let isPast = dueDate < Date()
                    let payment = payments.first { $0.quarter == quarter && $0.year == currentYear }
                    let isPaid = payment?.confirmed ?? false
                    
                    HStack(spacing: 12) {
                        // Status indicator
                        ZStack {
                            Circle()
                                .fill(isPaid ? Theme.primaryGreen : (isPast ? Theme.primaryRed : Theme.cardBackgroundLight))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: isPaid ? "checkmark" : (isPast ? "exclamationmark" : "clock"))
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        
                        // Quarter info
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Q\(quarter)")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            Text(dueDate, style: .date)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                        
                        Spacer()
                        
                        // Amount
                        if let payment = payment, payment.confirmed {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(payment.amount.currencyFormatted)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.primaryGreen)
                                Text("Paid")
                                    .font(.caption2)
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        } else {
                            Button(action: {
                                selectedQuarter = quarter
                                showPaymentSheet = true
                            }) {
                                Text("Record")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.primaryBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.primaryBlue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Payment History Section
    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment History")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            if payments.filter({ $0.confirmed }).isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundColor(Theme.textMuted)
                    Text("No payments recorded yet")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
            } else {
                ForEach(payments.filter { $0.confirmed }, id: \.id) { payment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Q\(payment.quarter) \(payment.year)")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            if let date = payment.datePaid {
                                Text("Paid \(date, style: .date)")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        
                        Spacer()
                        
                        Text(payment.amount.currencyFormatted)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.primaryGreen)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Record Payment Sheet
struct RecordPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let quarter: Int
    let year: Int
    let suggestedAmount: Double
    
    @State private var amount = ""
    @State private var paymentDate = Date()
    @State private var confirmPayment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Record Payment")
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Q\(quarter) \(year)")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    // Suggested amount
                    VStack(spacing: 4) {
                        Text("Suggested: \(suggestedAmount.currencyFormatted)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                        
                        Button(action: { amount = String(format: "%.2f", suggestedAmount) }) {
                            Text("Use Suggested Amount")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.primaryBlue)
                        }
                    }
                    
                    // Amount input
                    HStack {
                        Text("$")
                            .font(Theme.numberFont)
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("0.00", text: $amount)
                            .font(Theme.numberFont)
                            .foregroundColor(Theme.primaryGreen)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
                    
                    // Date picker
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                        .tint(Theme.primaryGreen)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                    
                    // Confirmation toggle
                    Toggle(isOn: $confirmPayment) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I confirm this payment was made")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Check your bank statement to verify")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .tint(Theme.primaryGreen)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: recordPayment) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Record Payment")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!confirmPayment || amount.isEmpty)
                    .opacity(confirmPayment && !amount.isEmpty ? 1 : 0.6)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    private func recordPayment() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        _ = PersistenceController.shared.recordTaxPayment(
            quarter: quarter,
            year: year,
            amount: amountValue,
            confirmed: true
        )
        
        // Cancel notifications for this quarter
        NotificationService.shared.cancelReminder(for: quarter, year: year)
        
        dismiss()
    }
}

#Preview {
    NavigationView {
        PaymentsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
