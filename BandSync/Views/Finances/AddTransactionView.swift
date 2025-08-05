import SwiftUI
import VisionKit

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var type: FinanceType = .expense
    @State private var category: FinanceCategory = .logistics
    @State private var amount: String = ""
    @State private var currency: String = "EUR"
    @State private var details: String = ""
    @State private var date = Date()
    
    @State private var showReceiptScanner = false
    @State private var scannedText = ""
    @State private var extractedFinanceRecord: FinanceRecord?
    @State private var isLoadingTransaction = false
    @State private var errorMessage: String?
    
    private var currencies = ["EUR", "USD", "UAH", "GBP", "CAD", "AUD", "CHF", "JPY", "PLN", "CZK", "SEK", "NOK", "DKK"]
    
    private var navigationTitle: String {
        if horizontalSizeClass == .compact {
            return NSLocalizedString("New Transaction", comment: "New transaction navigation title")
        } else {
            return NSLocalizedString("Add New Financial Transaction", comment: "Add new financial transaction navigation title")
        }
    }
    
    private var isAmountValid: Bool {
        if amount.isEmpty { return true }
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedAmount) != nil
    }
    
    private var formIsValid: Bool {
        let hasValidAmount = !amount.isEmpty && isAmountValid
        let hasCurrency = !currency.isEmpty
        return hasValidAmount && hasCurrency
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(
                        colors: colorScheme == .dark ?
                            [Color(hex: "0f0f23"), Color(hex: "16213e")] :
                            [Color(hex: "f8fafc"), Color(hex: "e2e8f0")]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Transaction Type", comment: "Transaction type label"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(NSLocalizedString("Choose Transaction Type", comment: "Choose transaction type description"))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                            
                            Picker("", selection: $type) {
                                Text(NSLocalizedString("Income", comment: "Income transaction type")).tag(FinanceType.income)
                                Text(NSLocalizedString("Expense", comment: "Expense transaction type")).tag(FinanceType.expense)
                            }
                            .pickerStyle(.segmented)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            .onChange(of: type) { _, newType in
                                if let firstCategory = FinanceCategory.forType(newType).first {
                                    category = firstCategory
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(hex: "1a1b2e").opacity(0.8) : Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 8)
                        )
                        
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "folder.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Category", comment: "Category label"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(NSLocalizedString("Select Category", comment: "Select category description"))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(categoryColor(for: category))
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: categoryIcon(for: category))
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(category.localizedTitle)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Picker(NSLocalizedString("Category", comment: "Category picker label"), selection: $category) {
                                ForEach(FinanceCategory.forType(type)) { cat in
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(categoryColor(for: cat))
                                                .frame(width: 24, height: 24)
                                            
                                            Image(systemName: categoryIcon(for: cat))
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text(cat.localizedTitle)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .tag(cat)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(hex: "1a1b2e").opacity(0.8) : Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 8)
                        )
                        
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "banknote.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Transaction Details", comment: "Transaction details label"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(NSLocalizedString("Enter amount and details", comment: "Enter amount and details description"))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(NSLocalizedString("Amount", comment: "Amount label"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    TextField(NSLocalizedString("0.00", comment: "Amount placeholder"), text: $amount)
                                        .keyboardType(.decimalPad)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(type == .income ? .green : .red)
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(type == .income ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    
                                    Menu {
                                        ForEach(currencies, id: \.self) { curr in
                                            Button {
                                                currency = curr
                                            } label: {
                                                Text(curr)
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(currency)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            
                                            Image(systemName: "chevron.down.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.blue.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                                
                                if !isAmountValid {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(NSLocalizedString("Please enter a valid amount", comment: "Invalid amount error message"))
                                            .font(.callout)
                                            .foregroundColor(.red)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(NSLocalizedString("Description", comment: "Description label"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField(NSLocalizedString("Add description", comment: "Add description placeholder"), text: $details)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(NSLocalizedString("Date", comment: "Date label"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(hex: "1a1b2e").opacity(0.8) : Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 8)
                        )
                        
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "doc.viewfinder.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Receipt", comment: "Receipt label"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    Text(NSLocalizedString("Scan or attach receipt", comment: "Scan or attach receipt description"))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: {
                                showReceiptScanner = true
                            }) {
                                HStack(spacing: 16) {
                                    if let _ = extractedFinanceRecord?.receiptUrl {
                                        ZStack {
                                            Circle()
                                                .fill(.green)
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "doc.text.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(NSLocalizedString("Receipt added", comment: "Receipt added status"))
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            
                                            Text(NSLocalizedString("Tap to change", comment: "Tap to change receipt"))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(.blue)
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "doc.text.viewfinder")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(NSLocalizedString("Scan Receipt", comment: "Scan receipt button"))
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                            
                                            Text(NSLocalizedString("Capture receipt details automatically", comment: "Capture receipt details description"))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(hex: "1a1b2e").opacity(0.8) : Color.white.opacity(0.9))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 8)
                        )
                        
                        Button {
                            saveTransaction()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                
                                Text(NSLocalizedString("Save Transaction", comment: "Save transaction button"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        formIsValid ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: formIsValid ? Color.blue.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)
                            )
                        }
                        .disabled(!formIsValid || isLoadingTransaction)
                        
                        if let errorMessage = errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(errorMessage)
                                    .font(.callout)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoadingTransaction {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 24) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            VStack(spacing: 8) {
                                Text(NSLocalizedString("Saving transaction", comment: "Saving transaction progress message"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(NSLocalizedString("Please wait", comment: "Please wait message"))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThickMaterial)
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                }
            }
            .sheet(isPresented: $showReceiptScanner) {
                EnhancedReceiptScannerView(
                    recognizedText: $scannedText,
                    extractedFinanceRecord: $extractedFinanceRecord,
                    onScanComplete: { path, result in
                        if let result = result {
                            if let extractedAmount = result.amount, amount.isEmpty {
                                amount = String(format: "%.2f", extractedAmount)
                            }
                            
                            if !result.details.isEmpty && details.isEmpty {
                                details = result.details
                            }
                            
                            if let resultDate = result.date {
                                date = resultDate
                            }
                        }
                    }
                )
            }
        }
    }
    
    private func saveTransaction() {
        let amountString = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(amountString),
              let groupId = AppState.shared.user?.groupId else {
            errorMessage = NSLocalizedString("Invalid amount or user group", comment: "Invalid amount or user group error")
            return
        }
        
        isLoadingTransaction = true
        errorMessage = nil
        
        let recordId = UUID().uuidString
        let receiptPath = extractedFinanceRecord?.receiptUrl
        
        let record = FinanceRecord(
            id: recordId,
            type: type,
            amount: amountValue,
            currency: currency.uppercased(),
            category: category.rawValue,
            details: details,
            date: date,
            receiptUrl: receiptPath,
            groupId: groupId
        )
        
        FinanceService.shared.add(record) { success in
            DispatchQueue.main.async {
                isLoadingTransaction = false
                
                if success {
                    dismiss()
                } else {
                    errorMessage = NSLocalizedString("Failed to save transaction", comment: "Failed to save transaction error")
                }
            }
        }
    }
    
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
