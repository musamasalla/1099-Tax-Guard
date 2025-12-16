//
//  ContentView.swift
//  1099 Tax Guard - Quarterly Tax Estimator for Freelancers
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.id, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var isLoading = true
    
    private var settings: UserSettings? { userSettings.first }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .tint(Theme.primaryGreen)
                    Text("Loading...")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 8)
                }
            } else if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .onAppear {
            // Check onboarding status after a brief delay to ensure Core Data is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasCompletedOnboarding = settings?.hasCompletedOnboarding ?? false
                isLoading = false
            }
        }
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Income Tab
            NavigationView {
                IncomeListView()
            }
            .tabItem {
                Image(systemName: "dollarsign.circle.fill")
                Text("Income")
            }
            .tag(1)
            
            // Deductions Tab
            NavigationView {
                DeductionListView()
            }
            .tabItem {
                Image(systemName: "doc.text.fill")
                Text("Deductions")
            }
            .tag(2)
            
            // Calculator Tab
            NavigationView {
                TaxCalculatorView()
            }
            .tabItem {
                Image(systemName: "percent")
                Text("Calculator")
            }
            .tag(3)
            
            // Settings Tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(4)
        }
        .tint(Theme.primaryGreen)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.cardBackground)
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.textMuted)]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.primaryGreen)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.primaryGreen)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
