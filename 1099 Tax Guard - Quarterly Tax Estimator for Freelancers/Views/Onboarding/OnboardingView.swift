//
//  OnboardingView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var persistenceController = PersistenceController.shared
    
    @State private var currentStep = 0
    @State private var selectedState: USState = .california
    @State private var expectedIncome: String = ""
    @State private var selectedFilingStatus: FilingStatus = .single
    @State private var showStatePicker = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentStep ? Theme.primaryGreen : Theme.cardBackgroundLight)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    stateSelectionStep
                        .tag(1)
                    
                    incomeStep
                        .tag(2)
                    
                    filingStatusStep
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
    }
    
    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App icon/logo
            ZStack {
                Circle()
                    .fill(Theme.greenGradient)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .shadow(color: Theme.primaryGreen.opacity(0.4), radius: 20)
            
            VStack(spacing: 16) {
                Text("1099 Tax Guard")
                    .font(Theme.largeTitleFont)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Your Quarterly Tax Estimator")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "dollarsign.circle.fill", title: "Track 1099 Income", color: Theme.primaryGreen)
                FeatureRow(icon: "doc.text.fill", title: "Manage Deductions", color: Theme.primaryBlue)
                FeatureRow(icon: "calculator.fill", title: "Calculate Taxes", color: Theme.accentPurple)
                FeatureRow(icon: "bell.fill", title: "Payment Reminders", color: Theme.accentGold)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            Button(action: { withAnimation { currentStep = 1 } }) {
                Text("Get Started")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - State Selection Step
    private var stateSelectionStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.blueGradient)
                
                Text("What state do you live in?")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to calculate your state taxes")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // State picker button
            Button(action: { showStatePicker = true }) {
                HStack {
                    Text(selectedState.fullName)
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.textSecondary)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // State tax info
            Text(selectedState.taxDescription)
                .font(Theme.captionFont)
                .foregroundColor(selectedState.hasNoIncomeTax ? Theme.primaryGreen : Theme.textSecondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { withAnimation { currentStep = 0 } }) {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: { withAnimation { currentStep = 2 } }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showStatePicker) {
            StatePickerSheet(selectedState: $selectedState, isPresented: $showStatePicker)
        }
    }
    
    // MARK: - Income Step
    private var incomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.greenGradient)
                
                Text("Expected Annual Income")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your best estimate of 1099 income for this year")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // Income input
            HStack {
                Text("$")
                    .font(Theme.mediumNumberFont)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("50,000", text: $expectedIncome)
                    .font(Theme.mediumNumberFont)
                    .foregroundColor(Theme.textPrimary)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            // Quick select amounts
            HStack(spacing: 12) {
                QuickAmountButton(amount: 25000, selectedAmount: $expectedIncome)
                QuickAmountButton(amount: 50000, selectedAmount: $expectedIncome)
                QuickAmountButton(amount: 100000, selectedAmount: $expectedIncome)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { withAnimation { currentStep = 1 } }) {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: { withAnimation { currentStep = 3 } }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(expectedIncome.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Filing Status Step
    private var filingStatusStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.premiumGradient)
                
                Text("Filing Status")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("How will you file your taxes?")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            // Filing status options
            VStack(spacing: 12) {
                ForEach(FilingStatus.allCases, id: \.self) { status in
                    Button(action: { selectedFilingStatus = status }) {
                        HStack {
                            Image(systemName: status.icon)
                                .font(.title2)
                                .foregroundColor(selectedFilingStatus == status ? Theme.primaryGreen : Theme.textSecondary)
                                .frame(width: 30)
                            
                            Text(status.displayName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            if selectedFilingStatus == status {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        }
                        .padding()
                        .background(selectedFilingStatus == status ? Theme.cardBackgroundLight : Theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedFilingStatus == status ? Theme.primaryGreen : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { withAnimation { currentStep = 2 } }) {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: completeOnboarding) {
                    Text("Start Tracking")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        let income = Double(expectedIncome.replacingOccurrences(of: ",", with: "")) ?? 50000
        
        _ = persistenceController.createOrUpdateUserSettings(
            state: selectedState,
            expectedIncome: income,
            filingStatus: selectedFilingStatus
        )
        
        // Request notification permission
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                NotificationService.shared.scheduleQuarterlyReminders()
            }
        }
        
        onComplete()
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
        }
    }
}

struct QuickAmountButton: View {
    let amount: Int
    @Binding var selectedAmount: String
    
    var body: some View {
        Button(action: {
            selectedAmount = "\(amount)"
        }) {
            Text("$\(amount / 1000)K")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.cardBackgroundLight)
                .cornerRadius(8)
        }
    }
}

struct StatePickerSheet: View {
    @Binding var selectedState: USState
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredStates: [USState] {
        if searchText.isEmpty {
            return USState.allCases
        }
        return USState.allCases.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List(filteredStates, id: \.self) { state in
                    Button(action: {
                        selectedState = state
                        isPresented = false
                    }) {
                        HStack {
                            Text(state.fullName)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            if state.hasNoIncomeTax {
                                Text("No Tax")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.primaryGreen)
                            }
                            
                            if state == selectedState {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        }
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search states")
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
