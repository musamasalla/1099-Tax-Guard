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
            ElectricBackground()
            
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
        .ignoresSafeArea(.all) // Ensure root view extends edge-to-edge
        .onAppear {
            // Set window background color to match theme
            setWindowBackgroundColor()
            
            // Check onboarding status after a brief delay to ensure Core Data is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasCompletedOnboarding = settings?.hasCompletedOnboarding ?? false
                isLoading = false
            }
        }
    }
    
    // MARK: - Set Window Background
    private func setWindowBackgroundColor() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }
            window.backgroundColor = UIColor(Theme.electricBlue)
        }
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationView { DashboardView() }
                case 1:
                    NavigationView { IncomeListView() }
                case 2:
                    NavigationView { DeductionListView() }
                case 3:
                    NavigationView { PaymentsView() }
                case 4:
                    NavigationView { SettingsView() }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar overlay
            CapsuleTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
