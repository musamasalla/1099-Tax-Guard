//
//  PersistenceController.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import CoreData
import CloudKit
import Combine

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    // Preview container for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for previews
        let income1 = Income(context: viewContext)
        income1.id = UUID()
        income1.clientName = "Uber"
        income1.amount = 1500.00
        income1.date = Date()
        income1.incomeType = IncomeType.k.rawValue
        income1.notes = "Weekly earnings"
        
        let income2 = Income(context: viewContext)
        income2.id = UUID()
        income2.clientName = "Upwork"
        income2.amount = 2500.00
        income2.date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        income2.incomeType = IncomeType.nec.rawValue
        income2.notes = "Web development project"
        
        let deduction1 = Deduction(context: viewContext)
        deduction1.id = UUID()
        deduction1.category = DeductionCategory.mileage.rawValue
        deduction1.amount = 134.0 // 200 miles * $0.67
        deduction1.date = Date()
        deduction1.notes = "200 miles business driving"
        
        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.state = USState.california.rawValue
        settings.expectedAnnualIncome = 75000
        settings.filingStatus = FilingStatus.single.rawValue
        settings.hasCompletedOnboarding = true
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "TaxGuardModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            
            // Enable CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CloudKit container identifier
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.taxguard.1099"
            )
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Core Data Saving
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - User Settings
    func getUserSettings() -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1
        
        do {
            return try container.viewContext.fetch(request).first
        } catch {
            print("Error fetching user settings: \(error)")
            return nil
        }
    }
    
    func createOrUpdateUserSettings(state: USState, expectedIncome: Double, filingStatus: FilingStatus) -> UserSettings {
        let context = container.viewContext
        
        if let existingSettings = getUserSettings() {
            existingSettings.state = state.rawValue
            existingSettings.expectedAnnualIncome = expectedIncome
            existingSettings.filingStatus = filingStatus.rawValue
            existingSettings.hasCompletedOnboarding = true
            save()
            return existingSettings
        } else {
            let newSettings = UserSettings(context: context)
            newSettings.id = UUID()
            newSettings.state = state.rawValue
            newSettings.expectedAnnualIncome = expectedIncome
            newSettings.filingStatus = filingStatus.rawValue
            newSettings.hasCompletedOnboarding = true
            save()
            return newSettings
        }
    }
    
    // MARK: - Income Operations
    func addIncome(clientName: String, amount: Double, date: Date, type: IncomeType, notes: String = "") -> Income {
        let context = container.viewContext
        let income = Income(context: context)
        income.id = UUID()
        income.clientName = clientName
        income.amount = amount
        income.date = date
        income.incomeType = type.rawValue
        income.notes = notes
        save()
        return income
    }
    
    func deleteIncome(_ income: Income) {
        let context = container.viewContext
        context.delete(income)
        save()
    }
    
    func fetchIncomes(for quarter: Int? = nil, year: Int? = nil) -> [Income] {
        let request: NSFetchRequest<Income> = Income.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Income.date, ascending: false)]
        
        var predicates: [NSPredicate] = []
        
        if let quarter = quarter, let year = year {
            let dateRange = QuarterHelper.dateRange(for: quarter, year: year)
            predicates.append(NSPredicate(format: "date >= %@ AND date < %@", dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching incomes: \(error)")
            return []
        }
    }
    
    // MARK: - Deduction Operations
    func addDeduction(category: DeductionCategory, amount: Double, date: Date, notes: String = "", receiptData: Data? = nil) -> Deduction {
        let context = container.viewContext
        let deduction = Deduction(context: context)
        deduction.id = UUID()
        deduction.category = category.rawValue
        deduction.amount = amount
        deduction.date = date
        deduction.notes = notes
        deduction.receiptImageData = receiptData
        save()
        return deduction
    }
    
    func deleteDeduction(_ deduction: Deduction) {
        let context = container.viewContext
        context.delete(deduction)
        save()
    }
    
    func fetchDeductions(for quarter: Int? = nil, year: Int? = nil) -> [Deduction] {
        let request: NSFetchRequest<Deduction> = Deduction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Deduction.date, ascending: false)]
        
        var predicates: [NSPredicate] = []
        
        if let quarter = quarter, let year = year {
            let dateRange = QuarterHelper.dateRange(for: quarter, year: year)
            predicates.append(NSPredicate(format: "date >= %@ AND date < %@", dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching deductions: \(error)")
            return []
        }
    }
    
    // MARK: - Tax Payment Operations
    func recordTaxPayment(quarter: Int, year: Int, amount: Double, confirmed: Bool = false) -> TaxPayment {
        let context = container.viewContext
        let payment = TaxPayment(context: context)
        payment.id = UUID()
        payment.quarter = Int16(quarter)
        payment.year = Int16(year)
        payment.amount = amount
        payment.datePaid = Date()
        payment.confirmed = confirmed
        save()
        return payment
    }
    
    func confirmPayment(_ payment: TaxPayment) {
        payment.confirmed = true
        payment.datePaid = Date()
        save()
    }
    
    func fetchTaxPayments(for year: Int? = nil) -> [TaxPayment] {
        let request: NSFetchRequest<TaxPayment> = TaxPayment.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaxPayment.year, ascending: false),
                                   NSSortDescriptor(keyPath: \TaxPayment.quarter, ascending: false)]
        
        if let year = year {
            request.predicate = NSPredicate(format: "year == %d", year)
        }
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching tax payments: \(error)")
            return []
        }
    }
}

// MARK: - Quarter Helper
struct QuarterHelper {
    static func currentQuarter() -> Int {
        let month = Calendar.current.component(.month, from: Date())
        return ((month - 1) / 3) + 1
    }
    
    static func currentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
    
    static func dateRange(for quarter: Int, year: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startMonth = (quarter - 1) * 3 + 1
        
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = startMonth
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = quarter == 4 ? year + 1 : year
        endComponents.month = quarter == 4 ? 1 : startMonth + 3
        endComponents.day = 1
        
        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(from: endComponents)!
        
        return (startDate, endDate)
    }
    
    static func quarterName(_ quarter: Int) -> String {
        switch quarter {
        case 1: return "Q1 (Jan-Mar)"
        case 2: return "Q2 (Apr-Jun)"
        case 3: return "Q3 (Jul-Sep)"
        case 4: return "Q4 (Oct-Dec)"
        default: return "Q\(quarter)"
        }
    }
    
    // IRS Quarterly Payment Due Dates
    static func dueDate(for quarter: Int, year: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        
        switch quarter {
        case 1:
            components.month = 4
            components.day = 15
        case 2:
            components.month = 6
            components.day = 15
        case 3:
            components.month = 9
            components.day = 15
        case 4:
            components.year = year + 1
            components.month = 1
            components.day = 15
        default:
            components.month = 1
            components.day = 15
        }
        
        return calendar.date(from: components) ?? Date()
    }
    
    static func nextDueDate() -> (quarter: Int, year: Int, date: Date) {
        let today = Date()
        let currentYear = currentYear()
        
        for q in 1...4 {
            let dueDate = dueDate(for: q, year: currentYear)
            if dueDate > today {
                return (q, currentYear, dueDate)
            }
        }
        
        // If all quarters have passed, return Q1 of next year
        return (1, currentYear + 1, dueDate(for: 1, year: currentYear + 1))
    }
    
    static func daysUntil(date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
}
