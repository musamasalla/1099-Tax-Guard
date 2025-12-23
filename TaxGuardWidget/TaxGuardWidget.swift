//
//  TaxGuardWidget.swift
//  TaxGuardWidget
//
//  Created by Musa Masalla on 2025/12/23.
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
            nextDeadline: getNextDeadline(),
            daysUntilDeadline: getDaysUntilDeadline(),
            totalIncome: 45000,
            totalDeductions: 12000
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaxGuardEntry>) -> Void) {
        let entry = TaxGuardEntry(
            date: Date(),
            quarterlyTaxDue: 2500,
            nextDeadline: getNextDeadline(),
            daysUntilDeadline: getDaysUntilDeadline(),
            totalIncome: 45000,
            totalDeductions: 12000
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getNextDeadline() -> String {
        let deadlines = [
            (month: 1, day: 15, label: "Jan 15"),
            (month: 4, day: 15, label: "Apr 15"),
            (month: 6, day: 15, label: "Jun 15"),
            (month: 9, day: 15, label: "Sep 15")
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
        let deadlines = [(1, 15), (4, 15), (6, 15), (9, 15)]
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        
        for (month, day) in deadlines {
            if let deadlineDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: day)),
               deadlineDate > now {
                return calendar.dateComponents([.day], from: now, to: deadlineDate).day ?? 30
            }
        }
        
        // Next year's Q4
        if let nextQ4 = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 15)) {
            return calendar.dateComponents([.day], from: now, to: nextQ4).day ?? 30
        }
        return 30
    }
}

// MARK: - Colors
struct WidgetColors {
    static let electricBlue = Color(red: 0.255, green: 0.212, blue: 0.945)
    static let deepBlue = Color(red: 0.165, green: 0.133, blue: 0.635)
    static let neonLime = Color(red: 0.91, green: 0.996, blue: 0.353)
    static let primaryGreen = Color(red: 0.06, green: 0.73, blue: 0.51)
}

// MARK: - Widget Entry View
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
            LinearGradient(
                colors: [WidgetColors.electricBlue, WidgetColors.deepBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(WidgetColors.neonLime)
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
                    .foregroundColor(WidgetColors.neonLime)
                
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
                colors: [WidgetColors.electricBlue, WidgetColors.deepBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(WidgetColors.neonLime)
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
                        .foregroundColor(WidgetColors.neonLime)
                    
                    Text("Due \(entry.nextDeadline)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(title: "Income", value: formatCurrency(entry.totalIncome), color: WidgetColors.primaryGreen)
                    StatRow(title: "Deductions", value: formatCurrency(entry.totalDeductions), color: WidgetColors.electricBlue)
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
                colors: [WidgetColors.electricBlue, WidgetColors.deepBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(WidgetColors.neonLime)
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quarterly Tax Due")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatCurrency(entry.quarterlyTaxDue))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(WidgetColors.neonLime)
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                HStack(spacing: 20) {
                    StatCard(title: "YTD Income", value: formatCurrency(entry.totalIncome), icon: "arrow.up.circle.fill", color: WidgetColors.primaryGreen)
                    StatCard(title: "Deductions", value: formatCurrency(entry.totalDeductions), icon: "arrow.down.circle.fill", color: WidgetColors.electricBlue)
                }
                
                Spacer()
                
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
struct TaxGuardWidget: Widget {
    let kind: String = "TaxGuardWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaxGuardProvider()) { entry in
            TaxGuardWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [WidgetColors.electricBlue, WidgetColors.deepBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("1099 Tax Guard")
        .description("View your quarterly tax estimates at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: .now, quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 23, totalIncome: 45000, totalDeductions: 12000)
}

#Preview(as: .systemMedium) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: .now, quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 23, totalIncome: 45000, totalDeductions: 12000)
}

#Preview(as: .systemLarge) {
    TaxGuardWidget()
} timeline: {
    TaxGuardEntry(date: .now, quarterlyTaxDue: 2500, nextDeadline: "Jan 15", daysUntilDeadline: 23, totalIncome: 45000, totalDeductions: 12000)
}
