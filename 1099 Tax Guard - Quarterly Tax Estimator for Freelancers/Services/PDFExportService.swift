//
//  PDFExportService.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation
import PDFKit
import UIKit

class PDFExportService {
    static let shared = PDFExportService()
    
    private init() {}
    
    // MARK: - Generate Year-End Summary PDF
    func generateYearEndSummary(
        year: Int,
        incomeByQuarter: [Int: Double],
        deductionsByCategory: [DeductionCategory: Double],
        taxPayments: [TaxPayment],
        userState: USState,
        filingStatus: FilingStatus
    ) -> Data? {
        let pageWidth: CGFloat = 612 // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = margin
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            
            let title = "1099 Tax Guard - Year-End Summary"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 35
            
            // Year
            let yearText = "Tax Year: \(year)"
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]
            yearText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25
            
            // Generated date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let generatedText = "Generated: \(dateFormatter.string(from: Date()))"
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            generatedText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 40
            
            // Divider
            drawDivider(at: yPosition, width: pageWidth - 2 * margin, xOffset: margin, in: context)
            yPosition += 20
            
            // Income by Quarter Section
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            "INCOME BY QUARTER".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            let itemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            var totalIncome: Double = 0
            for quarter in 1...4 {
                let income = incomeByQuarter[quarter] ?? 0
                totalIncome += income
                let quarterText = "Q\(quarter): \(income.currencyFormatted)"
                quarterText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: itemAttributes)
                yPosition += 20
            }
            
            yPosition += 5
            let totalIncomeText = "Total Income: \(totalIncome.currencyFormatted)"
            let totalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            totalIncomeText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: totalAttributes)
            yPosition += 35
            
            // Deductions by Category Section
            "DEDUCTIONS BY CATEGORY".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            var totalDeductions: Double = 0
            for (category, amount) in deductionsByCategory.sorted(by: { $0.value > $1.value }) {
                if amount > 0 {
                    totalDeductions += amount
                    let deductionText = "\(category.displayName): \(amount.currencyFormatted)"
                    deductionText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: itemAttributes)
                    yPosition += 20
                }
            }
            
            yPosition += 5
            let totalDeductionsText = "Total Deductions: \(totalDeductions.currencyFormatted)"
            totalDeductionsText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: totalAttributes)
            yPosition += 35
            
            // Net Income
            let netIncome = totalIncome - totalDeductions
            "NET SELF-EMPLOYMENT INCOME".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            let netIncomeText = netIncome.currencyFormatted
            let largeNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            netIncomeText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: largeNumberAttributes)
            yPosition += 40
            
            // Tax Calculations
            let taxCalc = TaxCalculationService.shared.calculateTaxes(
                grossIncome: totalIncome,
                deductions: totalDeductions,
                state: userState,
                filingStatus: filingStatus
            )
            
            "TAX SUMMARY".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            let taxItems = [
                ("Self-Employment Tax", taxCalc.selfEmploymentTax.total),
                ("Federal Income Tax", taxCalc.federalIncomeTax),
                ("State Tax (\(userState.rawValue))", taxCalc.stateTax),
                ("Total Tax Liability", taxCalc.totalTaxOwed)
            ]
            
            for (index, item) in taxItems.enumerated() {
                let attrs = index == taxItems.count - 1 ? totalAttributes : itemAttributes
                let taxText = "\(item.0): \(item.1.currencyFormatted)"
                taxText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: attrs)
                yPosition += 20
            }
            
            yPosition += 15
            let effectiveRateText = "Effective Tax Rate: \(taxCalc.effectiveTotalRate.percentFormatted)"
            effectiveRateText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: itemAttributes)
            yPosition += 35
            
            // Quarterly Payments Made
            "QUARTERLY PAYMENTS MADE".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25
            
            var totalPayments: Double = 0
            let yearPayments = taxPayments.filter { $0.year == year && $0.confirmed }
            
            if yearPayments.isEmpty {
                "No payments recorded".draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: itemAttributes)
                yPosition += 20
            } else {
                for payment in yearPayments {
                    totalPayments += payment.amount
                    let paymentText = "Q\(payment.quarter): \(payment.amount.currencyFormatted)"
                    paymentText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: itemAttributes)
                    yPosition += 20
                }
            }
            
            yPosition += 5
            let totalPaymentsText = "Total Payments: \(totalPayments.currencyFormatted)"
            totalPaymentsText.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: totalAttributes)
            yPosition += 25
            
            // Balance Due/Refund
            let balance = taxCalc.totalTaxOwed - totalPayments
            let balanceLabel = balance >= 0 ? "BALANCE DUE" : "ESTIMATED REFUND"
            let balanceColor = balance >= 0 ? UIColor.red : UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
            
            let balanceHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: balanceColor
            ]
            balanceLabel.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: balanceHeaderAttributes)
            yPosition += 25
            
            let balanceValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: balanceColor
            ]
            abs(balance).currencyFormatted.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: balanceValueAttributes)
            yPosition += 50
            
            // Footer
            drawDivider(at: yPosition, width: pageWidth - 2 * margin, xOffset: margin, in: context)
            yPosition += 15
            
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let footerText = "This is an estimate only. Please consult with a tax professional for accurate tax advice."
            footerText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: footerAttributes)
        }
        
        return data
    }
    
    private func drawDivider(at y: CGFloat, width: CGFloat, xOffset: CGFloat, in context: UIGraphicsPDFRendererContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: xOffset, y: y))
        path.addLine(to: CGPoint(x: xOffset + width, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    // MARK: - Save PDF
    func savePDF(data: Data, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfPath = documentsPath.appendingPathComponent("\(fileName).pdf")
        
        do {
            try data.write(to: pdfPath)
            return pdfPath
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}
