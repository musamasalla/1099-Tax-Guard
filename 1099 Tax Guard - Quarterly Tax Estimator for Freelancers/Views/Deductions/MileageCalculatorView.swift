//
//  MileageCalculatorView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI

struct MileageCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var miles = ""
    @State private var selectedDate = Date()
    @State private var tripPurpose = ""
    @State private var startLocation = ""
    @State private var endLocation = ""
    
    private let mileageRate = DeductionCategory.mileageRatePerMile // $0.67 for 2025
    
    private var calculatedAmount: Double {
        guard let milesValue = Double(miles), milesValue > 0 else { return 0 }
        return milesValue * mileageRate
    }
    
    private var isValid: Bool {
        guard let milesValue = Double(miles), milesValue > 0 else { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ElectricBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Mileage rate info
                        rateInfoCard
                        
                        // Miles input
                        milesInput
                        
                        // Calculated amount
                        calculatedAmountCard
                        
                        // Trip details
                        tripDetailsSection
                        
                        // Date
                        dateSection
                        
                        // Save button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Mileage")
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
    
    // MARK: - Rate Info Card
    private var rateInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.primaryBlue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("2025 IRS Mileage Rate")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text("$\(String(format: "%.2f", mileageRate)) per mile")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Miles Input
    private var milesInput: some View {
        VStack(spacing: 8) {
            Text("Miles Driven")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                TextField("0", text: $miles)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                
                Text("miles")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Calculated Amount Card
    private var calculatedAmountCard: some View {
        VStack(spacing: 8) {
            Text("Deduction Amount")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
            
            Text(calculatedAmount.currencyFormatted)
                .font(Theme.numberFont)
                .foregroundColor(Theme.primaryGreen)
            
            if let milesValue = Double(miles), milesValue > 0 {
                Text("\(String(format: "%.1f", milesValue)) miles × $\(String(format: "%.2f", mileageRate))")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.primaryGreen.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    // MARK: - Trip Details Section
    private var tripDetailsSection: some View {
        VStack(spacing: 12) {
            Text("Trip Details (Optional)")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Trip purpose (e.g., Client meeting)", text: $tripPurpose)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption2)
                        .foregroundColor(Theme.textMuted)
                    TextField("Start", text: $startLocation)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(Theme.textMuted)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption2)
                        .foregroundColor(Theme.textMuted)
                    TextField("End", text: $endLocation)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Date")
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
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveMileage) {
            HStack {
                Image(systemName: "car.fill")
                Text("Save Mileage Deduction")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.6)
    }
    
    // MARK: - Save Mileage
    private func saveMileage() {
        guard calculatedAmount > 0 else { return }
        
        var notes = ""
        if !tripPurpose.isEmpty {
            notes = tripPurpose
        }
        if !startLocation.isEmpty && !endLocation.isEmpty {
            notes += notes.isEmpty ? "" : " - "
            notes += "\(startLocation) → \(endLocation)"
        }
        if let milesValue = Double(miles) {
            notes += notes.isEmpty ? "" : " - "
            notes += "\(String(format: "%.1f", milesValue)) miles"
        }
        
        _ = PersistenceController.shared.addDeduction(
            category: .mileage,
            amount: calculatedAmount,
            date: selectedDate,
            notes: notes,
            receiptData: nil
        )
        
        dismiss()
    }
}

#Preview {
    MileageCalculatorView()
}
