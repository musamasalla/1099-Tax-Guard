//
//  TaxGuardApp.swift
//  1099 Tax Guard - Quarterly Tax Estimator for Freelancers
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData
import UserNotifications

@main
struct TaxGuardApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.background)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.primaryGreen)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
