//
//  AddIncomeView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var subscriptionService = SubscriptionService.shared
    
    @State private var clientName = ""
    @State private var amount = ""
    @State private var selectedDate = Date()
    @State private var selectedType: IncomeType = .nec
    @State private var notes = ""
    @State private var showPaywall = false
    
    // Common platforms for quick selection
    private let popularPlatforms = [
        "Uber", "Lyft", "Upwork", "Fiverr", "Etsy", 
        "Airbnb", "DoorDash", "Instacart", "TaskRabbit", "Other"
    ]
    
    private var isValid: Bool {
        !clientName.isEmpty && !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount input (prominent)
                        amountSection
                        
                        // Client/Platform
                        clientSection
                        
                        // Date picker
                        dateSection
                        
                        // Income type
                        incomeTypeSection
                        
                        // Notes
                        notesSection
                        
                        // Save button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Income")
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("0.00", text: $amount)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.primaryGreen)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Client Section
    private var clientSection: some View {
        VStack(spacing: 12) {
            Text("Client / Platform")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Quick select platforms
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(popularPlatforms, id: \.self) { platform in
                        Button(action: { clientName = platform }) {
                            Text(platform)
                                .font(Theme.captionFont)
                                .foregroundColor(clientName == platform ? .white : Theme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(clientName == platform ? Theme.primaryGreen : Theme.cardBackgroundLight)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Custom input
            TextField("Or enter client name", text: $clientName)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Payment Date")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Theme.primaryGreen)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Income Type Section
    private var incomeTypeSection: some View {
        VStack(spacing: 12) {
            Text("1099 Form Type")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(IncomeType.allCases, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(selectedType == type ? Theme.primaryGreen : Theme.textSecondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(type.description)
                                    .font(.caption2)
                                    .foregroundColor(Theme.textMuted)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        }
                        .padding()
                        .background(selectedType == type ? Theme.cardBackgroundLight : Theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedType == type ? Theme.primaryGreen : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: 8) {
            Text("Notes (Optional)")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Add any notes about this income", text: $notes, axis: .vertical)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3...6)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveIncome) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Income")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.6)
    }
    
    // MARK: - Save Income
    private func saveIncome() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        // Check free tier limit
        let currentTotal = fetchCurrentYTDIncome()
        if !subscriptionService.isPremium && 
           (currentTotal + amountValue) > SubscriptionService.freeIncomeLimit {
            showPaywall = true
            return
        }
        
        _ = PersistenceController.shared.addIncome(
            clientName: clientName,
            amount: amountValue,
            date: selectedDate,
            type: selectedType,
            notes: notes
        )
        
        dismiss()
    }
    
    private func fetchCurrentYTDIncome() -> Double {
        let request = Income.fetchRequest()
        let startOfYear = Calendar.current.date(from: DateComponents(year: QuarterHelper.currentYear(), month: 1, day: 1))!
        request.predicate = NSPredicate(format: "date >= %@", startOfYear as NSDate)
        
        do {
            let incomes = try viewContext.fetch(request)
            return incomes.reduce(0) { $0 + $1.amount }
        } catch {
            return 0
        }
    }
}

#Preview {
    AddIncomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
