//
//  IncomeListView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct IncomeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Income.date, ascending: false)],
        animation: .default
    )
    private var incomes: FetchedResults<Income>
    
    @State private var showAddIncome = false
    @State private var selectedQuarter: Int? = nil
    @State private var searchText = ""
    
    private var currentQuarter: Int { QuarterHelper.currentQuarter() }
    private var currentYear: Int { QuarterHelper.currentYear() }
    
    private var filteredIncomes: [Income] {
        var result = Array(incomes)
        
        // Filter by quarter if selected
        if let quarter = selectedQuarter {
            let range = QuarterHelper.dateRange(for: quarter, year: currentYear)
            result = result.filter { income in
                guard let date = income.date else { return false }
                return date >= range.start && date < range.end
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { income in
                income.clientName?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return result
    }
    
    private var totalAmount: Double {
        filteredIncomes.reduce(0) { $0 + $1.amount }
    }
    
    private var incomeByType: [IncomeType: Double] {
        var result: [IncomeType: Double] = [:]
        for income in filteredIncomes {
            if let typeRaw = income.incomeType, let type = IncomeType(rawValue: typeRaw) {
                result[type, default: 0] += income.amount
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            ElectricBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Summary header
                summaryHeader
                
                // Quarter filter
                quarterFilter
                
                // Income list
                if filteredIncomes.isEmpty {
                    emptyState
                } else {
                    incomeList
                }
            }
        }
        .navigationTitle("Income")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by client")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddIncome = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView()
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(selectedQuarter != nil ? "Q\(selectedQuarter!) Income" : "Total Income")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text(totalAmount.currencyFormatted)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.primaryGreen)
            }
            
            // Type breakdown
            HStack(spacing: 20) {
                ForEach(IncomeType.allCases, id: \.self) { type in
                    if let amount = incomeByType[type], amount > 0 {
                        VStack(spacing: 2) {
                            Text(type.displayName)
                                .font(.caption2)
                                .foregroundColor(Theme.textMuted)
                            Text(amount.wholeNumberFormatted)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
    }
    
    // MARK: - Quarter Filter
    private var quarterFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedQuarter == nil) {
                    selectedQuarter = nil
                }
                
                ForEach(1...4, id: \.self) { quarter in
                    FilterChip(
                        title: "Q\(quarter)",
                        isSelected: selectedQuarter == quarter
                    ) {
                        selectedQuarter = quarter
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Income List
    private var incomeList: some View {
        List {
            ForEach(Array(filteredIncomes.enumerated()), id: \.element.id) { index, income in
                IncomeRowView(income: income)
                    .listRowBackground(Theme.cardBackground)
                    .listRowSeparator(.hidden)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: true)
            }
            .onDelete(perform: deleteIncomes)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 90) // Account for capsule tab bar
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack {
            Spacer()
            
            EmptyStateView(
                icon: "dollarsign.circle",
                title: "No Income Yet",
                message: "Tap the + button to add your first income entry."
            )
            
            Button(action: { showAddIncome = true }) {
                Text("Add Income")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)
            
            Spacer()
        }
    }
    
    private func deleteIncomes(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredIncomes[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Income Row View
struct IncomeRowView: View {
    let income: Income
    
    var incomeType: IncomeType? {
        guard let typeRaw = income.incomeType else { return nil }
        return IncomeType(rawValue: typeRaw)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.primaryGreen.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: incomeType?.icon ?? "dollarsign.circle.fill")
                    .foregroundColor(Theme.primaryGreen)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(income.clientName ?? "Unknown")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 8) {
                    if let type = incomeType {
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.cardBackgroundLight)
                            .cornerRadius(4)
                    }
                    
                    if let date = income.date {
                        Text(date, style: .date)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(income.amount.currencyFormatted)
                .font(Theme.headlineFont)
                .foregroundColor(Theme.primaryGreen)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.primaryGreen : Theme.cardBackgroundLight)
                .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationView {
        IncomeListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
