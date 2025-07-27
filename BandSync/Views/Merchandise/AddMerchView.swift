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
                Section(header: Text("Images".localized)) {
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
                        Label(merchImages.isEmpty ? "Select images".localized : "Add more images".localized, systemImage: "photo.on.rectangle")
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
                Section(header: Text("Item Information".localized)) {
                    TextField("Name".localized, text: $name)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description".localized)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                    }
                    
                    TextField("Price (EUR)".localized, text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Cost (EUR, optional)".localized, text: $cost)
                        .keyboardType(.decimalPad)
                    
                    HStack {
                        TextField("Low stock threshold".localized, text: $lowStockThreshold)
                            .keyboardType(.numberPad)
                        
                        Spacer()
                        
                        Text(String.localizedStringWithFormat("%d items".localized, stock.total))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                // Category and subcategory
                Section(header: Text("Category".localized)) {
                    Picker("Category".localized, selection: $category) {
                        ForEach(MerchCategory.allCases) {
                            Text($0.rawValue.localized).tag($0)
                        }
                    }
                    .onChange(of: category) {
                        // Reset subcategory when changing category
                        subcategory = nil
                        
                        // Update suggested threshold
                        lowStockThreshold = String(category.suggestedLowStockThreshold)
                    }

                    // Dynamic subcategory selection
                    Picker("Subcategory".localized, selection: $subcategory) {
                        Text("Not Selected".localized).tag(Optional<MerchSubcategory>.none)
                        ForEach(MerchSubcategory.subcategories(for: category), id: \.self) {
                            Text($0.rawValue.localized).tag(Optional<MerchSubcategory>.some($0))
                        }
                    }
                }
                
                // Inventory
                Section(header: Text("Inventory".localized)) {
                    HStack {
                        TextField("SKU (optional)".localized, text: $sku)
                        
                        Button(action: {
                            // Generate an SKU if not specified
                            let item = createItem()
                            sku = item.generateSKU()
                        }) {
                            Text("Generate".localized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                // Stock section
                Section(header: Text(category == .clothing ? "Stock by sizes".localized : "Item quantity".localized)) {
                    if category == .clothing {
                        Stepper(String.localizedStringWithFormat("S: %d".localized, stock.S), value: $stock.S, in: 0...999)
                        Stepper(String.localizedStringWithFormat("M: %d".localized, stock.M), value: $stock.M, in: 0...999)
                        Stepper(String.localizedStringWithFormat("L: %d".localized, stock.L), value: $stock.L, in: 0...999)
                        Stepper(String.localizedStringWithFormat("XL: %d".localized, stock.XL), value: $stock.XL, in: 0...999)
                        Stepper(String.localizedStringWithFormat("XXL: %d".localized, stock.XXL), value: $stock.XXL, in: 0...999)
                    } else {
                        Stepper(String.localizedStringWithFormat("Quantity: %d".localized, stock.S), value: $stock.S, in: 0...999)
                    }
                }
            }
            .navigationTitle("Add Item".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized, role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            saveItem()
                        } label: {
                            Label("Save".localized, systemImage: "checkmark")
                        }
                        .disabled(isUploading || !isFormValid)
                        
                        Button {
                            showImportCSV = true
                        } label: {
                            Label("Import from CSV".localized, systemImage: "doc.text")
                        }
                        
                        Button {
                            saveDraft()
                        } label: {
                            Label("Save as Draft".localized, systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Text("Save".localized)
                    }
                    .disabled(isUploading || !isMinimallyValid)
                }
            }
            .overlay(
                Group {
                    if isUploading {
                        ProgressView("Uploading...".localized)
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error".localized),
                    message: Text(errorMessage ?? "An unknown error occurred".localized),
                    dismissButton: .default(Text("OK".localized))
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
                        errorMessage = "Error loading images: \(error.localizedDescription)".localized
                        showError = true
                    }
                    logger.error("Error loading image: \(error.localizedDescription)")
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if loadErrors > 0 {
                errorMessage = String.localizedStringWithFormat("Failed to load %d image(s)".localized, loadErrors)
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
            errorMessage = "User group not found".localized
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
                                self.errorMessage = "Failed to save item".localized
                                self.showError = true
                            }
                        }
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = "Error uploading images: \(error.localizedDescription)".localized
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
                    self.errorMessage = "Failed to save item".localized
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
            errorMessage = "Failed to save draft: \(error.localizedDescription)".localized
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
                Section(header: Text("CSV Data".localized)) {
                    ZStack(alignment: .topLeading) {
                        if csvText.isEmpty {
                            Text("Paste CSV Data Here".localized)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $csvText)
                            .frame(minHeight: 200)
                    }
                    
                    Button("Import from file".localized) {
                        showFilePicker = true
                    }
                }
                
                Section {
                    Button("Import CSV".localized) {
                        onImport(csvText)
                    }
                    .disabled(csvText.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                
                Section(header: Text("Sample Format".localized)) {
                    Text("Name,Description,Price,Category,Subcategory,S,M,L,XL,XXL\nT-Shirt,Band logo t-shirt,25,Clothing,T-shirt,10,15,20,10,5\nVinyl,Limited edition vinyl,30,Music,Vinyl Record,50,0,0,0,0".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Import From CSV".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel".localized) {
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
