//
//  AddDeductionView.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import SwiftUI
import PhotosUI
import CoreData

struct AddDeductionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var subscriptionService = SubscriptionService.shared
    
    @State private var selectedCategory: DeductionCategory = .equipment
    @State private var amount = ""
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showCamera = false
    @State private var showPaywall = false
    
    private var isValid: Bool {
        !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ElectricBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount input
                        amountSection
                        
                        // Category selection
                        categorySection
                        
                        // Date picker
                        dateSection
                        
                        // Receipt photo
                        receiptSection
                        
                        // Notes
                        notesSection
                        
                        // Save button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Deduction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $receiptImage)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        receiptImage = uiImage
                    }
                }
            }
        }
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center, spacing: 4) {
                Text("$")
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("0.00", text: $amount)
                    .font(Theme.numberFont)
                    .foregroundColor(Theme.primaryBlue)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(spacing: 12) {
            Text("Category")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DeductionCategory.allCases, id: \.self) { category in
                    let isLocked = category.isPremium && !subscriptionService.isPremium
                    
                    Button(action: {
                        if isLocked {
                            showPaywall = true
                        } else {
                            selectedCategory = category
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == category ? category.color : category.color.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: category.icon)
                                    .foregroundColor(selectedCategory == category ? .white : category.color)
                                
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Theme.accentPurple)
                                        .clipShape(Circle())
                                        .offset(x: 16, y: -16)
                                }
                            }
                            
                            Text(category.displayName)
                                .font(.caption2)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedCategory == category ? Theme.cardBackgroundLight : Theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Date")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Theme.primaryBlue)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Receipt Section
    private var receiptSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Receipt Photo")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                if !subscriptionService.isPremium {
                    Text("PRO")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accentPurple)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            if let image = receiptImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                    
                    Button(action: { receiptImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: 16) {
                    Button(action: {
                        if subscriptionService.isPremium {
                            showCamera = true
                        } else {
                            showPaywall = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Take Photo")
                                .font(Theme.captionFont)
                        }
                        .foregroundColor(Theme.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    if subscriptionService.isPremium {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                Text("Choose Photo")
                                    .font(Theme.captionFont)
                            }
                            .foregroundColor(Theme.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: 8) {
            Text("Notes (Optional)")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Add details about this expense", text: $notes, axis: .vertical)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(3...6)
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveDeduction) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Deduction")
            }
        }
        .buttonStyle(PrimaryButtonStyle(gradient: Theme.blueGradient))
        .disabled(!isValid)
        .opacity(isValid ? 1 : 0.6)
    }
    
    // MARK: - Save Deduction
    private func saveDeduction() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        var receiptData: Data? = nil
        if let image = receiptImage {
            receiptData = image.jpegData(compressionQuality: 0.7)
        }
        
        _ = PersistenceController.shared.addDeduction(
            category: selectedCategory,
            amount: amountValue,
            date: selectedDate,
            notes: notes,
            receiptData: receiptData
        )
        
        dismiss()
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddDeductionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
