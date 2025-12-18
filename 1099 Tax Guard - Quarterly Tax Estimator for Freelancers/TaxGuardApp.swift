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
        
        // Configure navigation bar appearance - TRANSPARENT to allow background to show through
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground() // Transparent, not opaque
        navAppearance.backgroundColor = .clear
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.primaryGreen)
        
        // Set window background color to match theme (eliminates black bars)
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.backgroundColor = UIColor(Theme.electricBlue)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
