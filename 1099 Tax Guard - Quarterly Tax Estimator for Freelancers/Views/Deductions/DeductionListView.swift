//
//  DeductionListView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct DeductionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var subscriptionService = SubscriptionService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deduction.date, ascending: false)],
        animation: .default
    )
    private var deductions: FetchedResults<Deduction>
    
    @State private var showAddDeduction = false
    @State private var showMileageCalculator = false
    @State private var selectedCategory: DeductionCategory? = nil
    
    private var filteredDeductions: [Deduction] {
        if let category = selectedCategory {
            return deductions.filter { $0.category == category.rawValue }
        }
        return Array(deductions)
    }
    
    private var totalDeductions: Double {
        filteredDeductions.reduce(0) { $0 + $1.amount }
    }
    
    private var deductionsByCategory: [DeductionCategory: Double] {
        var result: [DeductionCategory: Double] = [:]
        for deduction in deductions {
            if let catRaw = deduction.category, let category = DeductionCategory(rawValue: catRaw) {
                result[category, default: 0] += deduction.amount
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Summary header
                summaryHeader
                
                // Category filter
                categoryFilter
                
                // Deduction list
                if filteredDeductions.isEmpty {
                    emptyState
                } else {
                    deductionList
                }
            }
        }
        .navigationTitle("Deductions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddDeduction = true }) {
                        Label("Add Deduction", systemImage: "plus.circle")
                    }
                    Button(action: { showMileageCalculator = true }) {
                        Label("Log Mileage", systemImage: "car.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAddDeduction) {
            AddDeductionView()
        }
        .sheet(isPresented: $showMileageCalculator) {
            MileageCalculatorView()
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(selectedCategory?.displayName ?? "Total Deductions")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text(totalDeductions.currencyFormatted)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.primaryBlue)
            }
            
            // Top categories breakdown
            if selectedCategory == nil {
                HStack(spacing: 16) {
                    ForEach(topCategories, id: \.0) { category, amount in
                        VStack(spacing: 2) {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .font(.caption)
                            Text(amount.wholeNumberFormatted)
                                .font(.caption2)
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
    
    private var topCategories: [(DeductionCategory, Double)] {
        deductionsByCategory
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(DeductionCategory.allCases.filter { !$0.isPremium || subscriptionService.isPremium }, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Deduction List
    private var deductionList: some View {
        List {
            ForEach(filteredDeductions, id: \.id) { deduction in
                DeductionRowView(deduction: deduction)
                    .listRowBackground(Theme.cardBackground)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteDeductions)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(Theme.textMuted)
            
            Text("No deductions recorded")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textSecondary)
            
            Text("Track your business expenses to reduce your tax burden")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: { showAddDeduction = true }) {
                    Text("Add Deduction")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: { showMileageCalculator = true }) {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Log Mileage")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .frame(maxWidth: 300)
            
            Spacer()
        }
    }
    
    private func deleteDeductions(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredDeductions[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.save()
        }
    }
}

// MARK: - Deduction Row View
struct DeductionRowView: View {
    let deduction: Deduction
    @State private var showReceipt = false
    
    var category: DeductionCategory? {
        guard let catRaw = deduction.category else { return nil }
        return DeductionCategory(rawValue: catRaw)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill((category?.color ?? Theme.primaryBlue).opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category?.icon ?? "doc.text")
                    .foregroundColor(category?.color ?? Theme.primaryBlue)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.displayName ?? "Deduction")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 8) {
                    if let notes = deduction.notes, !notes.isEmpty {
                        Text(notes)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                            .lineLimit(1)
                    }
                    
                    if let date = deduction.date {
                        Text(date, style: .date)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }
            
            Spacer()
            
            // Receipt indicator
            if deduction.receiptImageData != nil {
                Button(action: { showReceipt = true }) {
                    Image(systemName: "photo.fill")
                        .foregroundColor(Theme.accentGold)
                        .font(.caption)
                }
            }
            
            // Amount
            Text(deduction.amount.currencyFormatted)
                .font(Theme.headlineFont)
                .foregroundColor(Theme.primaryBlue)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showReceipt) {
            if let imageData = deduction.receiptImageData,
               let uiImage = UIImage(data: imageData) {
                ReceiptImageView(image: uiImage)
            }
        }
    }
}

// MARK: - Receipt Image View
struct ReceiptImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DeductionListView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
