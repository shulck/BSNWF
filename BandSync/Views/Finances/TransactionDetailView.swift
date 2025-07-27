// TransactionDetailView.swift (SIMPLIFIED VERSION - only Firebase Storage)

import SwiftUI

struct TransactionDetailView: View {
    let record: FinanceRecord
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var navigationTitle: String {
        if horizontalSizeClass == .compact {
            return "Transaction Details".localized
        } else {
            return "Transaction Details".localized
        }
    }
    @State private var showShareSheet = false
    @State private var showShareReceiptSheet = false
    @State private var exportedPDF: Data?
    @State private var showAnimatedDetails = false
    @State private var showDeleteConfirmation = false
    @State private var showEditTransaction = false
    @State private var showReceiptImage = false
    @State private var receiptImage: UIImage?
    @State private var isDeleting = false
    @State private var deleteError: String?
    
    // States for loading from Firebase
    @State private var isLoadingReceiptImage = false
    @State private var receiptLoadError: String?

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Logistics": return "car.fill"
        case "Food": return "fork.knife"
        case "Equipment": return "guitars"
        case "Accommodation": return "house.fill"
        case "Promotion": return "megaphone.fill"
        case "Other": return "ellipsis.circle.fill"
        case "Performances": return "music.note"
        case "Merchandise": return "tshirt.fill"
        case "Royalties": return "music.quarternote.3"
        case "Sponsorship": return "dollarsign.circle"
        case "Video/Photo Production": return "camera.fill"
        default: return "questionmark.circle"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Logistics": return .blue
        case "Food": return .orange
        case "Equipment": return .purple
        case "Promotion": return .green
        case "Other": return .secondary
        case "Performances": return .red
        case "Merchandise": return .indigo
        case "Accommodation": return .teal
        case "Royalties": return .purple
        case "Sponsorship": return .green
        case "Video/Photo Production": return .pink
        default: return .gray
        }
    }

    var body: some View {
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
                VStack(spacing: 20) {
                    // Transaction Card with Amount and Type
                    VStack(spacing: 8) {
                        // Type indicator
                        HStack {
                            Spacer()
                            
                            Text(record.type == .income ? "Income" : "Expense")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(record.type == .income ? Color.green : Color.red)
                                )
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        
                        // Amount with animation
                        Text("\(record.type == .income ? "+" : "-")\(String(format: "%.2f", record.amount)) \(record.currency)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(record.type == .income ? .green : .red)
                            .padding(.vertical, 12)
                            .contentTransition(.numericText())
                        
                        // Date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            
                            Text(formattedDate(record.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 12)
                        
                        // Category Pill
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(categoryColor(for: record.category))
                                    .frame(width: 46, height: 46)
                                
                                Image(systemName: categoryIcon(for: record.category))
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            
                            Text(localizedCategoryName(for: record.category))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    colorScheme == .dark ?
                                        Color(hex: "252525") :
                                        categoryColor(for: record.category).opacity(0.1)
                                )
                        )
                        .offset(y: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Transaction Details Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Details".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        if !record.details.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(record.details)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f7f7f7"))
                                    )
                            }
                            .padding(.bottom, 8)
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .offset(y: showAnimatedDetails ? 0 : 20)
                            .animation(.easeOut.delay(0.3), value: showAnimatedDetails)
                        }
                        
                        if record.isCached == true {
                            HStack(spacing: 12) {
                                Image(systemName: "cloud.slash")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sync Status".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Waiting for synchronization".localized)
                                        .font(.callout)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .offset(y: showAnimatedDetails ? 0 : 20)
                            .animation(.easeOut.delay(0.4), value: showAnimatedDetails)
                        }
                        
                        // SIMPLIFIED Receipt section - only Firebase Storage
                        if let receiptUrl = record.receiptUrl,
                           !receiptUrl.isEmpty,
                           FirebaseStorageService.isFirebaseStorageURL(receiptUrl) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Receipt".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    if isLoadingReceiptImage {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        
                                        Text("Loading from cloud".localized)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "icloud.and.arrow.down")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Receipt in cloud storage".localized)
                                                .fontWeight(.medium)
                                            
                                            Text("Stored securely in Firebase".localized)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if !isLoadingReceiptImage {
                                        Button {
                                            loadReceiptFromFirebase(url: receiptUrl)
                                            showReceiptImage = true
                                        } label: {
                                            Text("View".localized)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.blue)
                                                )
                                        }
                                        
                                        Button {
                                            shareReceiptFromFirebase(url: receiptUrl)
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.8))
                                                )
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                
                                // Show loading error if any
                                if let error = receiptLoadError {
                                    Text("⚠️ \(error)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 4)
                                }
                            }
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .offset(y: showAnimatedDetails ? 0 : 20)
                            .animation(.easeOut.delay(0.5), value: showAnimatedDetails)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    // Action Buttons Card
                    VStack(spacing: 16) {
                        Text("Actions".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            actionButton(
                                icon: "square.and.arrow.up",
                                title: "Share".localized,
                                color: .blue,
                                action: {
                                    createPDF()
                                }
                            )
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .scaleEffect(showAnimatedDetails ? 1 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.5), value: showAnimatedDetails)
                            
                            actionButton(
                                icon: "pencil",
                                title: "Edit".localized,
                                color: .blue,
                                action: {
                                    showEditTransaction = true
                                }
                            )
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .scaleEffect(showAnimatedDetails ? 1 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.6), value: showAnimatedDetails)
                            
                            actionButton(
                                icon: "trash",
                                title: "Delete".localized,
                                color: .red,
                                action: {
                                    showDeleteConfirmation = true
                                }
                            )
                            .opacity(showAnimatedDetails ? 1 : 0)
                            .scaleEffect(showAnimatedDetails ? 1 : 0.8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.7), value: showAnimatedDetails)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    
                    if let error = deleteError {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                            .padding(.top, 16)
                    }
                }
                .padding()
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        createPDF()
                    } label: {
                        Label("Export PDF".localized, systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showEditTransaction = true
                    } label: {
                        Label("Edit".localized, systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Deleting transaction".localized)
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
        .sheet(isPresented: $showShareSheet) {
            if let pdf = exportedPDF {
                DocumentShareSheet(items: [pdf])
            }
        }
        .sheet(isPresented: $showShareReceiptSheet) {
            if let image = receiptImage {
                DocumentShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showEditTransaction) {
            EditTransactionView(record: record)
        }
        .sheet(isPresented: $showReceiptImage) {
            receiptImageSheet
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showAnimatedDetails = true
            }
        }
        .alert("Are you sure you want to delete this transaction?".localized, isPresented: $showDeleteConfirmation) {
            Button("Delete".localized, role: .destructive) {
                deleteTransaction()
            }
            Button("Cancel".localized, role: .cancel) {}
        }
    }
    
    // MARK: - Receipt Image Sheet
    private var receiptImageSheet: some View {
        ZStack {
            colorScheme == .dark ? Color(hex: "121212").ignoresSafeArea() : Color(hex: "f8f9fa").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Close".localized) {
                        showReceiptImage = false
                    }
                    .font(.headline)
                    .padding()
                    
                    Spacer()
                    
                    Text("Receipt".localized)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showReceiptImage = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showShareReceiptSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
                .background(
                    Rectangle()
                        .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                )
                
                // Image content
                ZStack {
                    if isLoadingReceiptImage {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Loading receipt from cloud".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "icloud.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Receipt unavailable".localized)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Could not load receipt from cloud storage".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            if let error = receiptLoadError {
                                Text(String(format: "Error: %@".localized, error))
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.red.opacity(0.1))
                                    )
                            }
                        }
                        .padding(32)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func actionButton(icon: String, title: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f8f8f8"))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // SIMPLIFIED Firebase loading
    private func loadReceiptFromFirebase(url: String) {
        print("☁️ Loading receipt from Firebase Storage: \(url)")
        
        receiptImage = nil
        receiptLoadError = nil
        isLoadingReceiptImage = true
        
        ReceiptStorage.loadReceipt(url: url) { image in
            DispatchQueue.main.async {
                isLoadingReceiptImage = false
                
                if let image = image {
                    print("✅ Receipt loaded successfully")
                    receiptImage = image
                    receiptLoadError = nil
                } else {
                    print("❌ Failed to load receipt")
                    receiptLoadError = "Failed to download from cloud storage".localized
                }
            }
        }
    }
    
    // Quick sharing
    private func shareReceiptFromFirebase(url: String) {
        if receiptImage == nil {
            loadReceiptFromFirebase(url: url)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if receiptImage != nil {
                showShareReceiptSheet = true
            }
        }
    }
    
    // SIMPLIFIED deletion
    private func deleteTransaction() {
        isDeleting = true
        deleteError = nil
        
        // Delete receipt from Firebase Storage if exists
        if let receiptUrl = record.receiptUrl,
           !receiptUrl.isEmpty,
           FirebaseStorageService.isFirebaseStorageURL(receiptUrl) {
            print("🗑️ Deleting receipt from Firebase Storage")
            ReceiptStorage.deleteReceipt(url: receiptUrl) { success in
                if success {
                    print("✅ Receipt deleted from Firebase Storage")
                } else {
                    print("❌ Failed to delete receipt from Firebase Storage")
                }
            }
        }
        
        // Delete transaction
        FinanceService.shared.delete(record) { success in
            DispatchQueue.main.async {
                isDeleting = false
                
                if success {
                    dismiss()
                } else {
                    deleteError = "Failed to delete the transaction. Please try again.".localized
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }

    private func createPDF() {
        guard let pdf = generateSafePDF() else { return }
        self.exportedPDF = pdf
        self.showShareSheet = true
    }

    private func generateSafePDF() -> Data? {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 595, height: 842), nil)
        UIGraphicsBeginPDFPage()

        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let titleFont = UIFont.boldSystemFont(ofSize: 24)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .paragraphStyle: paragraphStyle
        ]

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let title = "Financial Transaction".localized
        title.draw(in: CGRect(x: 50, y: 50, width: 495, height: 30), withAttributes: titleAttributes)

        var y = 100.0
        let lineHeight = 25.0

        let details = [
            String(format: "Type: %@".localized, record.type == .income ? "Income".localized : "Expense".localized),
            String(format: "Category: %@".localized, record.category),
            String(format: "Amount: %.2f %@".localized, record.amount, record.currency),
            String(format: "Date: %@".localized, formatter.string(from: record.date)),
            String(format: "Description: %@".localized, record.details)
        ]

        for detail in details {
            detail.draw(in: CGRect(x: 50, y: y, width: 495, height: lineHeight), withAttributes: attributes)
            y += lineHeight
        }
        
        // Receipt information
        if let receiptUrl = record.receiptUrl, !receiptUrl.isEmpty {
            y += lineHeight
            "Receipt: Available in Firebase Cloud Storage".localized.draw(in: CGRect(x: 50, y: y, width: 495, height: lineHeight), withAttributes: attributes)
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
    
    // MARK: - Helper Functions
    
    private func localizedCategoryName(for categoryString: String) -> String {
        if let category = FinanceCategory.allCases.first(where: { $0.rawValue == categoryString }) {
            return category.localizedTitle
        }
        return categoryString
    }
}
