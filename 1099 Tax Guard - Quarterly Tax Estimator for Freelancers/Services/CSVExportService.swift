//
//  CSVExportService.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/19.
//

import Foundation
import CoreData

class CSVExportService {
    static let shared = CSVExportService()
    
    private init() {}
    
    // MARK: - Export Incomes to CSV
    func exportIncomesToCSV(incomes: [Income], year: Int? = nil) -> Data? {
        var csvString = "Date,Client Name,Amount,Type,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let filteredIncomes: [Income]
        if let year = year {
            let calendar = Calendar.current
            filteredIncomes = incomes.filter { income in
                guard let date = income.date else { return false }
                return calendar.component(.year, from: date) == year
            }
        } else {
            filteredIncomes = incomes
        }
        
        for income in filteredIncomes {
            let date = income.date.map { dateFormatter.string(from: $0) } ?? ""
            let clientName = escapeCSV(income.clientName ?? "Unknown")
            let amount = String(format: "%.2f", income.amount)
            let type = escapeCSV(income.incomeType ?? "Other")
            let notes = escapeCSV(income.notes ?? "")
            
            csvString += "\(date),\(clientName),\(amount),\(type),\(notes)\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    // MARK: - Export Deductions to CSV
    func exportDeductionsToCSV(deductions: [Deduction], year: Int? = nil) -> Data? {
        var csvString = "Date,Category,Amount,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let filteredDeductions: [Deduction]
        if let year = year {
            let calendar = Calendar.current
            filteredDeductions = deductions.filter { deduction in
                guard let date = deduction.date else { return false }
                return calendar.component(.year, from: date) == year
            }
        } else {
            filteredDeductions = deductions
        }
        
        for deduction in filteredDeductions {
            let date = deduction.date.map { dateFormatter.string(from: $0) } ?? ""
            let category = escapeCSV(deduction.category ?? "Other")
            let amount = String(format: "%.2f", deduction.amount)
            let notes = escapeCSV(deduction.notes ?? "")
            
            csvString += "\(date),\(category),\(amount),\(notes)\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    // MARK: - Export Tax Payments to CSV
    func exportPaymentsToCSV(payments: [TaxPayment], year: Int? = nil) -> Data? {
        var csvString = "Year,Quarter,Amount,Date Paid,Confirmed\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let filteredPayments: [TaxPayment]
        if let year = year {
            filteredPayments = payments.filter { $0.year == year }
        } else {
            filteredPayments = payments
        }
        
        for payment in filteredPayments {
            let year = String(payment.year)
            let quarter = "Q\(payment.quarter)"
            let amount = String(format: "%.2f", payment.amount)
            let datePaid = payment.datePaid.map { dateFormatter.string(from: $0) } ?? "Not paid"
            let confirmed = payment.confirmed ? "Yes" : "No"
            
            csvString += "\(year),\(quarter),\(amount),\(datePaid),\(confirmed)\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    // MARK: - Export All Data to CSV
    func exportAllDataToCSV(
        incomes: [Income],
        deductions: [Deduction],
        payments: [TaxPayment],
        year: Int? = nil
    ) -> Data? {
        var csvString = ""
        
        // Header
        csvString += "1099 TAX GUARD - DATA EXPORT\n"
        if let year = year {
            csvString += "Year: \(year)\n"
        } else {
            csvString += "All Years\n"
        }
        csvString += "Exported: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n"
        csvString += "\n"
        
        // Incomes Section
        csvString += "=== INCOMES ===\n"
        if let incomeData = exportIncomesToCSV(incomes: incomes, year: year),
           let incomeString = String(data: incomeData, encoding: .utf8) {
            csvString += incomeString
        }
        csvString += "\n"
        
        // Deductions Section
        csvString += "=== DEDUCTIONS ===\n"
        if let deductionData = exportDeductionsToCSV(deductions: deductions, year: year),
           let deductionString = String(data: deductionData, encoding: .utf8) {
            csvString += deductionString
        }
        csvString += "\n"
        
        // Payments Section
        csvString += "=== TAX PAYMENTS ===\n"
        if let paymentData = exportPaymentsToCSV(payments: payments, year: year),
           let paymentString = String(data: paymentData, encoding: .utf8) {
            csvString += paymentString
        }
        
        return csvString.data(using: .utf8)
    }
    
    // MARK: - Save CSV File
    func saveCSV(data: Data, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let csvPath = documentsPath.appendingPathComponent("\(fileName).csv")
        
        do {
            try data.write(to: csvPath)
            return csvPath
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper: Escape CSV field
    private func escapeCSV(_ string: String) -> String {
        var result = string
        // If string contains comma, newline, or double quote, wrap in quotes
        if result.contains(",") || result.contains("\n") || result.contains("\"") {
            // Escape existing double quotes by doubling them
            result = result.replacingOccurrences(of: "\"", with: "\"\"")
            result = "\"\(result)\""
        }
        return result
    }
}
