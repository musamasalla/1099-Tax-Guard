//
//  SettingsView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var subscriptionService = SubscriptionService.shared
    @ObservedObject var notificationService = NotificationService.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.id, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var selectedState: USState = .california
    @State private var selectedFilingStatus: FilingStatus = .single
    @State private var expectedIncome: String = ""
    @State private var notificationsEnabled = true
    @State private var showStatePicker = false
    @State private var showPaywall = false
    @State private var showTaxCalculator = false
    @State private var showYearEndSummary = false
    
    private var settings: UserSettings? { userSettings.first }
    
    var body: some View {
        ZStack {
            ElectricBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Subscription status
                    subscriptionSection
                    
                    // Tax Tools (Calculator, Summary)
                    taxToolsSection
                    
                    // Tax settings
                    taxSettingsSection
                    
                    // Notifications
                    notificationSection
                    
                    // About
                    aboutSection
                    
                    // Legal
                    legalSection
                }
                .padding()
                .padding(.bottom, 90) // Account for capsule tab bar
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showStatePicker) {
            StatePickerSheet(selectedState: $selectedState, isPresented: $showStatePicker)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: selectedState) { _, _ in saveSettings() }
        .onChange(of: selectedFilingStatus) { _, _ in saveSettings() }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            if subscriptionService.isPremium {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(Theme.accentGold)
                            Text("Premium Member")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                        }
                        Text("All features unlocked")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.primaryGreen)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(Theme.premiumGradient)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentGold.opacity(0.5), lineWidth: 1)
                )
            } else {
                Button(action: { showPaywall = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(Theme.headlineFont)
                                .foregroundColor(.white)
                            Text("Unlimited tracking, PDF exports & more")
                                .font(Theme.captionFont)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Theme.premiumGradient)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Tax Tools Section
    private var taxToolsSection: some View {
        VStack(spacing: 12) {
            Text("Tax Tools")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                // Tax Calculator
                NavigationLink(destination: TaxCalculatorView()) {
                    HStack {
                        Image(systemName: "function")
                            .font(.title2)
                            .foregroundColor(Theme.primaryGreen)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tax Calculator")
                                .font(Theme.subheadlineFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Estimate your quarterly taxes")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding()
                }
                
                Divider()
                    .background(Theme.textSecondary.opacity(0.3))
                
                // Year-End Summary
                NavigationLink(destination: YearEndSummaryView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(Theme.primaryBlue)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Year-End Summary")
                                .font(Theme.subheadlineFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Full year tax report")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding()
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Tax Settings Section
    private var taxSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tax Settings")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 0) {
                // State
                Button(action: { showStatePicker = true }) {
                    SettingsRow(
                        icon: "mappin.circle.fill",
                        iconColor: Theme.primaryBlue,
                        title: "State",
                        value: selectedState.fullName
                    )
                }
                
                Divider().background(Theme.cardBackgroundLight).padding(.leading, 48)
                
                // Filing Status
                NavigationLink(destination: FilingStatusPicker(selectedStatus: $selectedFilingStatus)) {
                    SettingsRow(
                        icon: "person.circle.fill",
                        iconColor: Theme.primaryGreen,
                        title: "Filing Status",
                        value: selectedFilingStatus.displayName
                    )
                }
                
                Divider().background(Theme.cardBackgroundLight).padding(.leading, 48)
                
                // Expected Income
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Theme.accentGold)
                        .font(.title2)
                    
                    Text("Expected Annual Income")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    TextField("$0", text: $expectedIncome)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: expectedIncome) { _, _ in saveSettings() }
                }
                .padding()
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Notification Section
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 0) {
                Toggle(isOn: $notificationsEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Theme.accentGold)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Payment Reminders")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("7, 3, and 1 day before due dates")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
                .tint(Theme.primaryGreen)
                .padding()
                .onChange(of: notificationsEnabled) { _, newValue in
                    Task {
                        if newValue {
                            let granted = await notificationService.requestAuthorization()
                            if granted {
                                notificationService.scheduleQuarterlyReminders()
                            }
                        } else {
                            notificationService.cancelAllReminders()
                        }
                    }
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 0) {
                NavigationLink(destination: YearEndSummaryView()) {
                    SettingsRow(
                        icon: "chart.bar.doc.horizontal.fill",
                        iconColor: Theme.accentPurple,
                        title: "Year-End Summary",
                        value: ""
                    )
                }
                
                Divider().background(Theme.cardBackgroundLight).padding(.leading, 48)
                
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: Theme.primaryBlue,
                    title: "Version",
                    value: "1.0.0"
                )
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legal")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 0) {
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    SettingsRow(
                        icon: "hand.raised.fill",
                        iconColor: Theme.textSecondary,
                        title: "Privacy Policy",
                        value: ""
                    )
                }
                
                Divider().background(Theme.cardBackgroundLight).padding(.leading, 48)
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: Theme.textSecondary,
                        title: "Terms of Service",
                        value: ""
                    )
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(12)
            
            Text("This app provides estimates only. Consult a tax professional for accurate tax advice.")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Load/Save Settings
    private func loadSettings() {
        if let settings = settings {
            if let stateRaw = settings.state, let state = USState(rawValue: stateRaw) {
                selectedState = state
            }
            if let statusRaw = settings.filingStatus, let status = FilingStatus(rawValue: statusRaw) {
                selectedFilingStatus = status
            }
            expectedIncome = String(format: "%.0f", settings.expectedAnnualIncome)
        }
        notificationsEnabled = notificationService.isAuthorized
    }
    
    private func saveSettings() {
        let income = Double(expectedIncome.replacingOccurrences(of: ",", with: "")) ?? 50000
        _ = PersistenceController.shared.createOrUpdateUserSettings(
            state: selectedState,
            expectedIncome: income,
            filingStatus: selectedFilingStatus
        )
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
            
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textMuted)
        }
        .padding()
    }
}

// MARK: - Filing Status Picker
struct FilingStatusPicker: View {
    @Binding var selectedStatus: FilingStatus
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ElectricBackground()
            
            List(FilingStatus.allCases, id: \.self) { status in
                Button(action: {
                    selectedStatus = status
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: status.icon)
                            .foregroundColor(Theme.primaryGreen)
                        
                        Text(status.displayName)
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        if status == selectedStatus {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.primaryGreen)
                        }
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Filing Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
