//
//  EditTransactionView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 10.05.2025.
//

import SwiftUI

struct EditTransactionView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var type: FinanceType
    @State private var category: String
    @State private var amount: String
    @State private var currency: String
    @State private var details: String
    @State private var date: Date
    @State private var isLoadingTransaction = false
    @State private var errorMessage: String?
    @State private var showDatePicker = false
    @State private var showCategoryPicker = false
    
    // Adaptive window title
    private var navigationTitle: String {
        if horizontalSizeClass == .compact {
            return NSLocalizedString("Edit Transaction", comment: "Edit transaction navigation title")
        } else {
            return NSLocalizedString("Edit Financial Transaction", comment: "Edit financial transaction navigation title")
        }
    }
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    let record: FinanceRecord
    private var currencies = ["EUR", "USD", "GBP"]
    
    init(record: FinanceRecord) {
        self.record = record
        _type = State(initialValue: record.type)
        _category = State(initialValue: record.category)
        _amount = State(initialValue: String(format: "%.2f", record.amount))
        _currency = State(initialValue: record.currency)
        _details = State(initialValue: record.details)
        _date = State(initialValue: record.date)
    }
    
    private var isAmountValid: Bool {
        guard !amount.isEmpty else { return true }
        return Double(amount.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    private var formIsValid: Bool {
        return isAmountValid && !amount.isEmpty && !currency.isEmpty && !category.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient similar to FinancesView
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark ?
                            [Color(hex: "1a1a1a"), Color(hex: "121212")] :
                            [Color(hex: "f8f9fa"), Color(hex: "f1f3f5")]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Transaction Type Card
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("Transaction Type", comment: "Transaction type label"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Picker("Type", selection: $type) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text(NSLocalizedString("Income", comment: "Income transaction type"))
                                }
                                .foregroundColor(.green)
                                .tag(FinanceType.income)
                                
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text(NSLocalizedString("Expense", comment: "Expense transaction type"))
                                }
                                .foregroundColor(.red)
                                .tag(FinanceType.expense)
                            }
                            .pickerStyle(.segmented)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color(hex: "252525") : Color.white.opacity(0.5))
                            )
                            .onChange(of: type) { _, newType in
                                if !FinanceCategory.forType(newType).contains(where: { $0.rawValue == category }) {
                                    category = FinanceCategory.forType(newType).first?.rawValue ?? "Other"
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        
                        // Category Card
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("Category", comment: "Category label"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(categoryColorForDisplay)
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: categoryIconForDisplay)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(category)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        .sheet(isPresented: $showCategoryPicker) {
                            NavigationView {
                                categoryPickerView
                                    .navigationTitle(NSLocalizedString("Select Category", comment: "Select category navigation title"))
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .confirmationAction) {
                                            Button(NSLocalizedString("Done", comment: "Done button")) {
                                                showCategoryPicker = false
                                            }
                                        }
                                    }
                            }
                        }
                        
                        // Amount Card
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("Amount", comment: "Amount label"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Amount field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("Value", comment: "Value label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField(NSLocalizedString("0.00", comment: "Amount placeholder"), text: $amount)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(type == .income ? .green : .red)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                        )
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Currency picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("Currency", comment: "Currency label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Menu {
                                        ForEach(currencies, id: \.self) { curr in
                                            Button(curr) {
                                                currency = curr
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(currency)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 80)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                        )
                                    }
                                }
                            }
                            
                            if !isAmountValid {
                                Text(NSLocalizedString("Invalid amount format", comment: "Invalid amount format error"))
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        
                        // Details Card
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("Details", comment: "Details label"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextEditor(text: $details)
                                .font(.body)
                                .padding(12)
                                .frame(minHeight: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        
                        // Date Card
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("Date", comment: "Date label"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack {
                                Button {
                                    withAnimation {
                                        showDatePicker.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        
                                        Text(dateFormatter.string(from: date))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .rotationEffect(showDatePicker ? .degrees(180) : .degrees(0))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if showDatePicker {
                                    DatePicker("", selection: $date, displayedComponents: [.date])
                                        .datePickerStyle(GraphicalDatePickerStyle())
                                        .padding(.top, 8)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )
                        
                        // Save Button - Large Floating Style
                        Button {
                            updateRecord()
                        } label: {
                            Text(NSLocalizedString("Save Changes", comment: "Save changes button"))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            formIsValid ?
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: formIsValid ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                                )
                        }
                        .disabled(!formIsValid || isLoadingTransaction)
                        
                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
                        updateRecord()
                    }
                    .font(.headline)
                    .foregroundColor(formIsValid ? .blue : .gray)
                    .disabled(!formIsValid || isLoadingTransaction)
                }
            }
            .overlay {
                if isLoadingTransaction {
                    ZStack {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text(NSLocalizedString("Saving changes", comment: "Saving changes progress message"))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "252525") : .white)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    }
                }
            }
        }
    }
    
    // MARK: - Category Picker View
    private var categoryPickerView: some View {
        List {
            ForEach(FinanceCategory.forType(type)) { cat in
                Button {
                    category = cat.rawValue
                    showCategoryPicker = false
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(categoryColor(for: cat))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: categoryIcon(for: cat))
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Text(cat.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        if cat.rawValue == category {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Category Display Helpers
    
    // Display the icon for the currently selected category
    private var categoryIconForDisplay: String {
        // Find the FinanceCategory for the current string-based category
        if let categoryEnum = FinanceCategory.allCases.first(where: { $0.rawValue == category }) {
            return categoryIcon(for: categoryEnum)
        } else if category == "Video/Photo Production" {
            return "camera.fill"
        } else {
            return "questionmark.circle"
        }
    }
    
    // Display the color for the currently selected category
    private var categoryColorForDisplay: Color {
        // Find the FinanceCategory for the current string-based category
        if let categoryEnum = FinanceCategory.allCases.first(where: { $0.rawValue == category }) {
            return categoryColor(for: categoryEnum)
        } else if category == "Video/Photo Production" {
            return .pink
        } else {
            return .gray
        }
    }

    // MARK: - Update Function
    private func updateRecord() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = NSLocalizedString("Invalid amount format", comment: "Invalid amount format error")
            return
        }
        
        isLoadingTransaction = true
        
        let updatedRecord = FinanceRecord(
            id: record.id,
            type: type,
            amount: amountValue,
            currency: currency.uppercased(),
            category: category,
            details: details,
            date: date,
            receiptUrl: record.receiptUrl,
            groupId: record.groupId
        )
        
        FinanceService.shared.update(updatedRecord) { success in
            DispatchQueue.main.async {
                isLoadingTransaction = false
                
                if success {
                    dismiss()
                } else {
                    errorMessage = NSLocalizedString("Failed to update transaction", comment: "Failed to update transaction error")
                }
            }
        }
    }
    
    // MARK: - Category Icon and Color Helpers
    private func categoryIcon(for category: FinanceCategory) -> String {
        switch category {
        case .logistics: return "car.fill"
        case .food: return "fork.knife"
        case .gear: return "guitars"
        case .promo: return "megaphone.fill"
        case .other: return "ellipsis.circle.fill"
        case .performance: return "music.note"
        case .merch: return "tshirt.fill"
        case .accommodation: return "house.fill"
        case .royalties: return "music.quarternote.3"
        case .sponsorship: return "dollarsign.circle"
        case .production: return "film"
        case .mediaProduction: return "camera.fill"
        }
    }

    private func categoryColor(for category: FinanceCategory) -> Color {
        switch category {
        case .logistics: return .blue
        case .food: return .orange
        case .gear: return .purple
        case .promo: return .green
        case .other: return .secondary
        case .performance: return .red
        case .merch: return .indigo
        case .accommodation: return .teal
        case .royalties: return .purple
        case .sponsorship: return .green
        case .production: return .pink
        case .mediaProduction: return .mint
        }
    }
}
