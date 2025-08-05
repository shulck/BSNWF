import SwiftUI
import PhotosUI
import os.log

struct AddMerchView: View {
    @Environment(\.dismiss) var dismiss
    private let logger = Logger(subsystem: "com.bandsync.app", category: "AddMerchView")

    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var category: MerchCategory = .clothing
    @State private var subcategory: MerchSubcategory?
    @State private var stock = MerchSizeStock()
    @State private var lowStockThreshold = "5"
    @State private var cost = ""
    @State private var sku = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var merchImages: [UIImage] = []
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showImportCSV = false
    @State private var csvData: String?

    var body: some View {
        NavigationView {
            Form {
                // Item image
                Section(header: Text(NSLocalizedString("Images", comment: "Section header for product images"))) {
                    if !merchImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<merchImages.count, id: \.self) { index in
                                    Image(uiImage: merchImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .overlay(
                                            Button(action: {
                                                merchImages.remove(at: index)
                                                selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .padding(4)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                            .offset(x: 5, y: -5),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    PhotosPicker(selection: $selectedImages, maxSelectionCount: 5, matching: .images) {
                        Label(merchImages.isEmpty ? NSLocalizedString("Select images", comment: "Button text to select product images") : NSLocalizedString("Add more images", comment: "Button text to add more product images"), systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .onChange(of: selectedImages) {
                        loadImages(from: selectedImages)
                    }
                }

                // Basic information
                Section(header: Text(NSLocalizedString("Item Information", comment: "Section header for product basic information"))) {
                    TextField(NSLocalizedString("Name", comment: "Product name input field"), text: $name)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text(NSLocalizedString("Description", comment: "Product description placeholder"))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                    }
                    
                    TextField(NSLocalizedString("Price (EUR)", comment: "Product price input field"), text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField(NSLocalizedString("Cost (EUR, optional)", comment: "Product cost input field"), text: $cost)
                        .keyboardType(.decimalPad)
                    
                    HStack {
                        TextField(NSLocalizedString("Low stock threshold", comment: "Low stock threshold input field"), text: $lowStockThreshold)
                            .keyboardType(.numberPad)
                        
                        Spacer()
                        
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d items", comment: "Items count format"), stock.total))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                // Category and subcategory
                Section(header: Text(NSLocalizedString("Category", comment: "Section header for product category"))) {
                    Picker(NSLocalizedString("Category", comment: "Category picker label"), selection: $category) {
                        ForEach(MerchCategory.allCases) {
                            Text($0.localizedName).tag($0)
                        }
                    }
                    .onChange(of: category) {
                        // Reset subcategory when changing category
                        subcategory = nil
                        
                        // Update suggested threshold
                        lowStockThreshold = String(category.suggestedLowStockThreshold)
                    }

                    // Dynamic subcategory selection
                    Picker(NSLocalizedString("Subcategory", comment: "Subcategory picker label"), selection: $subcategory) {
                        Text(NSLocalizedString("Not Selected", comment: "Option for no subcategory selected")).tag(Optional<MerchSubcategory>.none)
                        ForEach(MerchSubcategory.subcategories(for: category), id: \.self) {
                            Text($0.localizedName).tag(Optional<MerchSubcategory>.some($0))
                        }
                    }
                }
                
                // Inventory
                Section(header: Text(NSLocalizedString("Inventory", comment: "Section header for inventory management"))) {
                    HStack {
                        TextField(NSLocalizedString("SKU (optional)", comment: "SKU input field"), text: $sku)
                        
                        Button(action: {
                            // Generate an SKU if not specified
                            let item = createItem()
                            sku = item.generateSKU()
                        }) {
                            Text(NSLocalizedString("Generate", comment: "Button to generate SKU"))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                // Stock section
                Section(header: Text(category == .clothing ? NSLocalizedString("Stock by sizes", comment: "Section header for clothing stock by sizes") : NSLocalizedString("Item quantity", comment: "Section header for item quantity"))) {
                    if category == .clothing {
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("S: %d", comment: "Size S stock format"), stock.S), value: $stock.S, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("M: %d", comment: "Size M stock format"), stock.M), value: $stock.M, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("L: %d", comment: "Size L stock format"), stock.L), value: $stock.L, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("XL: %d", comment: "Size XL stock format"), stock.XL), value: $stock.XL, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("XXL: %d", comment: "Size XXL stock format"), stock.XXL), value: $stock.XXL, in: 0...999)
                    } else {
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("Quantity: %d", comment: "General quantity format"), stock.S), value: $stock.S, in: 0...999)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Add Item", comment: "Navigation title for add merchandise item screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in add item screen"), role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            saveItem()
                        } label: {
                            Label(NSLocalizedString("Save", comment: "Save button in add item menu"), systemImage: "checkmark")
                        }
                        .disabled(isUploading || !isFormValid)
                        
                        Button {
                            showImportCSV = true
                        } label: {
                            Label(NSLocalizedString("Import from CSV", comment: "Import from CSV button"), systemImage: "doc.text")
                        }
                        
                        Button {
                            saveDraft()
                        } label: {
                            Label(NSLocalizedString("Save as Draft", comment: "Save as draft button"), systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Text(NSLocalizedString("Save", comment: "Save menu button"))
                    }
                    .disabled(isUploading || !isMinimallyValid)
                }
            }
            .overlay(
                Group {
                    if isUploading {
                        ProgressView(NSLocalizedString("Uploading...", comment: "Progress message while uploading item"))
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text(NSLocalizedString("Error", comment: "Error alert title")),
                    message: Text(errorMessage ?? NSLocalizedString("An unknown error occurred", comment: "Generic error message")),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK button in error alert")))
                )
            }
            .sheet(isPresented: $showImportCSV) {
                CSVImportView { importedData in
                    csvData = importedData
                    showImportCSV = false
                    
                    // Process the CSV
                    if let csvString = csvData,
                       let groupId = AppState.shared.user?.groupId,
                       let items = ImportExportService.shared.importItemsFromCSV(csv: csvString, groupId: groupId),
                       let firstItem = items.first {
                        
                        // Use the first item from CSV
                        name = firstItem.name
                        description = firstItem.description
                        price = String(firstItem.price)
                        category = firstItem.category
                        subcategory = firstItem.subcategory
                        stock = firstItem.stock
                        lowStockThreshold = String(firstItem.lowStockThreshold)
                        
                        if let costValue = firstItem.cost {
                            cost = String(costValue)
                        }
                        
                        if let skuValue = firstItem.sku {
                            sku = skuValue
                        }
                    }
                }
            }
        }
    }

    // Form validation
    private var isFormValid: Bool {
        !name.isEmpty &&
        !price.isEmpty &&
        Double(price) != nil &&
        (price as NSString).doubleValue > 0 &&
        Int(lowStockThreshold) != nil &&
        merchImages.count > 0
    }
    
    // Minimal validation for saving drafts
    private var isMinimallyValid: Bool {
        !name.isEmpty && Double(price) != nil
    }
    
    // Load selected images
    private func loadImages(from items: [PhotosPickerItem]) {
        let dispatchGroup = DispatchGroup()
        var loadErrors = 0
        
        for (index, item) in items.enumerated() {
            dispatchGroup.enter()
            
            Task {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                // If index already exists in collection - replace, otherwise append
                                if index < merchImages.count {
                                    merchImages[index] = uiImage
                                } else {
                                    merchImages.append(uiImage)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                loadErrors += 1
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        loadErrors += 1
                        errorMessage = String(format: NSLocalizedString("Error loading images: %@", comment: "Error message when image loading fails"), error.localizedDescription)
                        showError = true
                    }
                    logger.error("Error loading image: \(error.localizedDescription)")
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if loadErrors > 0 {
                errorMessage = String.localizedStringWithFormat(NSLocalizedString("Failed to load %d image(s)", comment: "Error message for failed image loading with count"), loadErrors)
                showError = true
            }
        }
    }
    
    // Create item from form data
    private func createItem() -> MerchItem {
        let priceValue = Double(price) ?? 0
        let costValue = Double(cost)
        let thresholdValue = Int(lowStockThreshold) ?? category.suggestedLowStockThreshold
        let groupId = AppState.shared.user?.groupId ?? ""
        
        var actualStock = stock
        
        // For non-clothing items, only use S for stock
        if category != .clothing {
            actualStock = MerchSizeStock(S: stock.S, M: 0, L: 0, XL: 0, XXL: 0)
        }
        
        return MerchItem(
            name: name,
            description: description,
            price: priceValue,
            category: category,
            subcategory: subcategory,
            stock: actualStock,
            groupId: groupId,
            lowStockThreshold: thresholdValue,
            cost: costValue
        )
    }

    // Save item
    private func saveItem() {
        guard AppState.shared.user?.groupId != nil else {
            errorMessage = NSLocalizedString("User group not found", comment: "Error message when user group is not found")
            showError = true
            return
        }

        isUploading = true
        errorMessage = nil
        
        let item = createItem()

        // If there are images, upload them to Firebase Storage
        if !merchImages.isEmpty {
            MerchImageManager.shared.uploadImages(merchImages, for: item) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let urls):
                        // Create item with image URLs from Firebase Storage
                        var updatedItem = item
                        updatedItem.imageUrls = urls.map { $0.absoluteString }
                        
                        if let firstUrl = urls.first {
                            updatedItem.imageURL = firstUrl.absoluteString
                        }

                        MerchService.shared.addItem(updatedItem) { success in
                            self.isUploading = false
                            if success {
                                self.dismiss()
                            } else {
                                self.errorMessage = NSLocalizedString("Failed to save item", comment: "Error message when item saving fails")
                                self.showError = true
                            }
                        }
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = String(format: NSLocalizedString("Error uploading images: %@", comment: "Error message when image upload fails"), error.localizedDescription)
                        self.showError = true
                    }
                }
            }
        } else {
            // Create item without images
            MerchService.shared.addItem(item) { success in
                self.isUploading = false
                if success {
                    self.dismiss()
                } else {
                    self.errorMessage = NSLocalizedString("Failed to save item", comment: "Error message when item saving fails")
                    self.showError = true
                }
            }
        }
    }
    
    // Save draft locally
    private func saveDraft() {
        let item = createItem()
        let encoder = JSONEncoder()
        
        do {
            let itemData = try encoder.encode(item)
            
            // Save to UserDefaults
            var drafts = UserDefaults.standard.array(forKey: "merch_item_drafts") as? [Data] ?? []
            drafts.append(itemData)
            UserDefaults.standard.set(drafts, forKey: "merch_item_drafts")
            
            dismiss()
        } catch {
            errorMessage = String(format: NSLocalizedString("Failed to save draft: %@", comment: "Error message when draft saving fails"), error.localizedDescription)
            showError = true
            logger.error("Failed to save draft: \(error.localizedDescription)")
        }
    }
}

// CSV Import View
struct CSVImportView: View {
    var onImport: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var csvText = ""
    @State private var showFilePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("CSV Data", comment: "Section header for CSV data input"))) {
                    ZStack(alignment: .topLeading) {
                        if csvText.isEmpty {
                            Text(NSLocalizedString("Paste CSV Data Here", comment: "Placeholder text for CSV input"))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $csvText)
                            .frame(minHeight: 200)
                    }
                    
                    Button(NSLocalizedString("Import from file", comment: "Button to import CSV from file")) {
                        showFilePicker = true
                    }
                }
                
                Section {
                    Button(NSLocalizedString("Import CSV", comment: "Button to import CSV data")) {
                        onImport(csvText)
                    }
                    .disabled(csvText.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                
                Section(header: Text(NSLocalizedString("Sample Format", comment: "Section header for CSV sample format"))) {
                    Text(NSLocalizedString("Name,Description,Price,Category,Subcategory,S,M,L,XL,XXL\nT-Shirt,Band logo t-shirt,25,Clothing,T-shirt,10,15,20,10,5\nVinyl,Limited edition vinyl,30,Music,Vinyl Record,50,0,0,0,0", comment: "Sample CSV format text"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(NSLocalizedString("Import From CSV", comment: "Navigation title for CSV import screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in CSV import screen")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker { url in
                    loadFile(from: url)
                }
            }
        }
    }
    
    private func loadFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let text = String(data: data, encoding: .utf8) {
                csvText = text
            }
        } catch {
            // Handle file loading error appropriately for production
            Logger(subsystem: "com.bandsync.app", category: "CSVImport")
                .error("Error loading file: \(error.localizedDescription)")
        }
    }
}

// Document Picker for importing CSV files
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText, .text])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Secure access to the selected file
            guard url.startAccessingSecurityScopedResource() else { return }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            parent.onPick(url)
        }
    }
}
