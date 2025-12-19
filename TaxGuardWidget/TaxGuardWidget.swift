//
//  TaxGuardWidget.swift
//  TaxGuardWidget
//
//  Created by Musa Masalla on 2025/12/19.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct TaxGuardEntry: TimelineEntry {
    let date: Date
    let quarterlyTaxDue: Double
    let nextDeadline: String
    let daysUntilDeadline: Int
    let totalIncome: Double
    let totalDeductions: Double
}

// MARK: - Timeline Provider
struct TaxGuardProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaxGuardEntry {
        TaxGuardEntry(
            date: Date(),
            quarterlyTaxDue: 2500,
            nextDeadline: "Jan 15",
            daysUntilDeadline: 30,
            totalIncome: 45000,
            totalDeductions: 12000
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaxGuardEntry) -> Void) {
        let entry = TaxGuardEntry(
            date: Date(),
            quarterlyTaxDue: 2500,
            nextDeadline: "Jan 15",
            daysUntilDeadline: 30,
            totalIncome: 45000,
            totalDeductions: 12000
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaxGuardEntry>) -> Void) {
        // In production, this would fetch from shared App Group container
        let entry = TaxGuardEntry(
            date: Date(),
            quarterlyTaxDue: calculateQuarterlyTax(),
            nextDeadline: getNextDeadline(),
            daysUntilDeadline: getDaysUntilDeadline(),
            totalIncome: getTotalIncome(),
            totalDeductions: getTotalDeductions()
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Data Helpers (would use App Groups in production)
    private func calculateQuarterlyTax() -> Double {
        // Placeholder - would calculate from shared data
        return 2500
    }
    
    private func getNextDeadline() -> String {
        let deadlines = [
            (month: 1, day: 15, label: "Jan 15"),  // Q4
            (month: 4, day: 15, label: "Apr 15"),  // Q1
            (month: 6, day: 15, label: "Jun 15"),  // Q2
            (month: 9, day: 15, label: "Sep 15")   // Q3
        ]
        
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        
        for deadline in deadlines {
            if let deadlineDate = calendar.date(from: DateComponents(year: currentYear, month: deadline.month, day: deadline.day)),
               deadlineDate > now {
                return deadline.label
            }
        }
        
        return "Jan 15"
    }
    
    private func getDaysUntilDeadline() -> Int {
        // Placeholder
        return 30
    }
    
    private func getTotalIncome() -> Double {
        return 45000
    }
    
    private func getTotalDeductions() -> Double {
        return 12000
    }
}

// MARK: - Widget Views
struct TaxGuardWidgetEntryView: View {
    var entry: TaxGuardProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: TaxGuardEntry
    
    var body: some View {
        ZStack {
            // Electric Blue gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.255, green: 0.212, blue: 0.945),
                    Color(red: 0.165, green: 0.133, blue: 0.635)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353)) // Neon lime
                        .font(.title3)
                    Spacer()
                    Text(entry.nextDeadline)
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("Q\(currentQuarter()) Tax Due")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(formatCurrency(entry.quarterlyTaxDue))
                    .font(.title2.bold())
                    .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353))
                
                Text("\(entry.daysUntilDeadline) days left")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
        }
    }
    
    private func currentQuarter() -> Int {
        let month = Calendar.current.component(.month, from: Date())
        return ((month - 1) / 3) + 1
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: TaxGuardEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.255, green: 0.212, blue: 0.945),
                    Color(red: 0.165, green: 0.133, blue: 0.635)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left side - Tax Due
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353))
                        Text("1099 Tax Guard")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Next Payment")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatCurrency(entry.quarterlyTaxDue))
                        .font(.title.bold())
                        .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353))
                    
                    Text("Due \(entry.nextDeadline)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                // Right side - Stats
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(title: "Income", value: formatCurrency(entry.totalIncome), color: .green)
                    StatRow(title: "Deductions", value: formatCurrency(entry.totalDeductions), color: .blue)
                    StatRow(title: "Days Left", value: "\(entry.daysUntilDeadline)", color: .orange)
                }
            }
            .padding()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: TaxGuardEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.255, green: 0.212, blue: 0.945),
                    Color(red: 0.165, green: 0.133, blue: 0.635)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353))
                        .font(.title2)
                    Text("1099 Tax Guard")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(entry.nextDeadline)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                // Main amount
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quarterly Tax Due")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatCurrency(entry.quarterlyTaxDue))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color(red: 0.91, green: 0.996, blue: 0.353))
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                // Stats grid
                HStack(spacing: 20) {
                    StatCard(title: "YTD Income", value: formatCurrency(entry.totalIncome), icon: "arrow.up.circle.fill", color: .green)
                    StatCard(title: "Deductions", value: formatCurrency(entry.totalDeductions), icon: "arrow.down.circle.fill", color: .blue)
                }
                
                Spacer()
                
                // Footer
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(entry.daysUntilDeadline) days until deadline")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget Configuration
@main
struct TaxGuardWidget: Widget {
    let kind: String = "TaxGuardWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaxGuardProvider()) { entry in
            TaxGuardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("1099 Tax Guard")
        .description("View your quarterly tax estimates at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: Date(), quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 30, totalIncome: 45000, totalDeductions: 12000)
}

#Preview(as: .systemMedium) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: Date(), quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 30, totalIncome: 45000, totalDeductions: 12000)
}

#Preview(as: .systemLarge) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: Date(), quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 30, totalIncome: 45000, totalDeductions: 12000)
}
