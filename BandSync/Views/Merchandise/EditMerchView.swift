import SwiftUI
import PhotosUI

struct EditMerchView: View {
    @Environment(\.dismiss) var dismiss
    let item: MerchItem

    @State private var name: String
    @State private var description: String
    @State private var price: String
    @State private var cost: String
    @State private var category: MerchCategory
    @State private var subcategory: MerchSubcategory?
    @State private var stock: MerchSizeStock
    @State private var lowStockThreshold: String
    @State private var sku: String
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var merchImages: [UIImage] = []
    @State private var existingImageUrls: [String] = []
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDeleteAlert = false

    init(item: MerchItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _description = State(initialValue: item.description)
        _price = State(initialValue: String(item.price))
        _cost = State(initialValue: item.cost != nil ? String(item.cost!) : "")
        _category = State(initialValue: item.category)
        _subcategory = State(initialValue: item.subcategory)
        _stock = State(initialValue: item.stock)
        _lowStockThreshold = State(initialValue: String(item.lowStockThreshold))
        _sku = State(initialValue: item.sku ?? "")
        
        // Store existing image URLs
        if let urls = item.imageUrls {
            _existingImageUrls = State(initialValue: urls)
        } else if let url = item.imageURL {
            _existingImageUrls = State(initialValue: [url])
        } else {
            _existingImageUrls = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Item images
                Section(header: Text(NSLocalizedString("Images", comment: "Header for merchandise images section"))) {
                    // Show existing images
                    if !existingImageUrls.isEmpty || !merchImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Existing images
                                ForEach(existingImageUrls.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        MerchImageView(imageUrl: existingImageUrls[index], item: item)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Button(action: {
                                            removeExistingImage(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red)
                                                .background(Color.white, in: Circle())
                                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }
                                
                                // New images
                                ForEach(0..<merchImages.count, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: merchImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Button(action: {
                                            merchImages.remove(at: index)
                                            selectedImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red)
                                                .background(Color.white, in: Circle())
                                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .frame(height: 116)
                    }
                    
                    PhotosPicker(selection: $selectedImages, maxSelectionCount: 5, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text(NSLocalizedString("Add more images", comment: "Button to add more merchandise images"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .onChange(of: selectedImages) {
                        loadImages(from: selectedImages)
                    }
                }

                // Basic information
                Section(header: Text(NSLocalizedString("Item Information", comment: "Header for basic merchandise item information section"))) {
                    TextField(NSLocalizedString("Name", comment: "Placeholder for merchandise item name field"), text: $name)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text(NSLocalizedString("Description", comment: "Placeholder for merchandise item description field"))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                    }
                    
                    TextField(NSLocalizedString("Price (EUR)", comment: "Placeholder for merchandise item price field in EUR"), text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField(NSLocalizedString("Cost (EUR, optional)", comment: "Placeholder for merchandise item cost field in EUR (optional)"), text: $cost)
                        .keyboardType(.decimalPad)
                    
                    if !cost.isEmpty && Double(cost) != nil && Double(price) != nil {
                        let costValue = Double(cost) ?? 0
                        let priceValue = Double(price) ?? 0
                        
                        if costValue > 0 && priceValue > costValue {
                            let margin = ((priceValue - costValue) / priceValue) * 100
                            
                            HStack {
                                Text(NSLocalizedString("Profit Margin", comment: "Label for calculated profit margin percentage"))
                                Spacer()
                                Text("\(margin, specifier: "%.1f")%")
                                    .foregroundColor(margin > 50 ? .green : .primary)
                                    .bold(margin > 50)
                            }
                        }
                    }
                    
                    TextField(NSLocalizedString("Low stock threshold", comment: "Placeholder for merchandise low stock threshold field"), text: $lowStockThreshold)
                        .keyboardType(.numberPad)
                }

                // Category and subcategory
                Section(header: Text(NSLocalizedString("Category", comment: "Header for merchandise category section"))) {
                    Picker(NSLocalizedString("Category", comment: "Label for merchandise category picker"), selection: $category) {
                        ForEach(MerchCategory.allCases) {
                            Text($0.localizedName).tag($0)
                        }
                    }
                    .onChange(of: category) {
                        // If new category is different from old one and subcategory doesn't belong to new category
                        if category != item.category,
                           let currentSubcategory = subcategory,
                           !MerchSubcategory.subcategories(for: category).contains(currentSubcategory) {
                            subcategory = nil
                        }
                    }

                    Picker(NSLocalizedString("Subcategory", comment: "Label for merchandise subcategory picker"), selection: $subcategory) {
                        Text(NSLocalizedString("Not Selected", comment: "Option for no subcategory selected")).tag(Optional<MerchSubcategory>.none)
                        ForEach(MerchSubcategory.subcategories(for: category), id: \.self) {
                            Text($0.localizedName).tag(Optional<MerchSubcategory>.some($0))
                        }
                    }
                }
                
                // Inventory
                Section(header: Text(NSLocalizedString("Inventory", comment: "Header for merchandise inventory section"))) {
                    HStack {
                        TextField(NSLocalizedString("SKU", comment: "Placeholder for merchandise SKU field"), text: $sku)
                        
                        Button(action: {
                            // Generate an SKU if not specified
                            let tempItem = createUpdatedItem()
                            sku = tempItem.generateSKU()
                        }) {
                            Text(NSLocalizedString("Generate", comment: "Button to generate SKU automatically"))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                // Stock by sizes or quantity
                Section(header: Text(category == .clothing ? NSLocalizedString("Stock by sizes", comment: "Header for clothing stock by sizes") : NSLocalizedString("Item quantity", comment: "Header for general item quantity"))) {
                    if category == .clothing {
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("S: %d", comment: "Small size stock counter with quantity"), stock.S), value: $stock.S, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("M: %d", comment: "Medium size stock counter with quantity"), stock.M), value: $stock.M, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("L: %d", comment: "Large size stock counter with quantity"), stock.L), value: $stock.L, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("XL: %d", comment: "Extra Large size stock counter with quantity"), stock.XL), value: $stock.XL, in: 0...999)
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("XXL: %d", comment: "Double Extra Large size stock counter with quantity"), stock.XXL), value: $stock.XXL, in: 0...999)
                    } else {
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("Quantity: %d", comment: "General item quantity counter"), stock.S), value: $stock.S, in: 0...999)
                    }
                }
                
                // Delete section
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("Delete Item", comment: "Button to delete merchandise item"))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Edit Item", comment: "Navigation title for edit merchandise item screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Button to save merchandise item changes")) {
                        saveChanges()
                    }
                    .disabled(isUploading || !isFormValid)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Button to cancel merchandise item editing"), role: .cancel) {
                        dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if isUploading {
                        ProgressView(NSLocalizedString("Saving...", comment: "Progress indicator when saving merchandise item"))
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
                    message: Text(errorMessage ?? NSLocalizedString("An unknown error occurred", comment: "Generic error message when error is unknown")),
                    dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK button in alert")))
                )
            }
            .alert(NSLocalizedString("Delete Item", comment: "Alert title for deleting merchandise item"), isPresented: $showDeleteAlert) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button in delete confirmation alert"), role: .cancel) { }
                Button(NSLocalizedString("Delete", comment: "Delete button in delete confirmation alert"), role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text(NSLocalizedString("Are you sure you want to delete this item? This action cannot be undone.", comment: "Confirmation message for deleting merchandise item"))
            }
        }
        .onAppear {
            loadExistingImages()
        }
    }

    // Form validation
    private var isFormValid: Bool {
        !name.isEmpty &&
        !price.isEmpty &&
        Double(price) != nil &&
        (price as NSString).doubleValue > 0 &&
        Int(lowStockThreshold) != nil &&
        (lowStockThreshold as NSString).integerValue >= 0 &&
        (existingImageUrls.count + merchImages.count > 0)
    }

    // Load existing images
    private func loadExistingImages() {
        // Load existing image URLs into UIImage objects if needed
        // This is only needed if you want to manipulate the existing images
    }
    
    // Load new selected images
    private func loadImages(from items: [PhotosPickerItem]) {
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        merchImages.append(uiImage)
                    }
                }
            }
        }
    }
    
    // Remove existing image
    private func removeExistingImage(at index: Int) {
        if index < existingImageUrls.count {
            existingImageUrls.remove(at: index)
        }
    }
    
    // Create updated item from form data
    private func createUpdatedItem() -> MerchItem {
        var updatedItem = item
        updatedItem.name = name
        updatedItem.description = description
        updatedItem.price = Double(price) ?? item.price
        
        if let costValue = Double(cost) {
            updatedItem.cost = costValue
        } else {
            updatedItem.cost = nil
        }
        
        updatedItem.category = category
        updatedItem.subcategory = subcategory
        
        // Update stock depending on category
        if category == .clothing {
            // For clothing save all sizes
            updatedItem.stock = stock
        } else {
            // For other categories save total quantity in S, other sizes = 0
            updatedItem.stock = MerchSizeStock(S: stock.S, M: 0, L: 0, XL: 0, XXL: 0)
        }
        
        updatedItem.lowStockThreshold = Int(lowStockThreshold) ?? item.lowStockThreshold
        updatedItem.sku = sku.isEmpty ? nil : sku
        updatedItem.updatedAt = Date()
        
        return updatedItem
    }

    // Save changes - Firebase Storage only
    private func saveChanges() {
        isUploading = true
        errorMessage = nil
        
        var updatedItem = createUpdatedItem()
        
        // If there are new images to upload, upload them to Firebase Storage
        if !merchImages.isEmpty {
            MerchImageManager.shared.uploadImages(merchImages, for: updatedItem) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let newImageUrls):
                        // Combine existing URLs with new Firebase Storage URLs
                        let newUrls = newImageUrls.map { $0.absoluteString }
                        let combinedUrls = self.existingImageUrls + newUrls
                        
                        updatedItem.imageUrls = combinedUrls
                        
                        // Set the first image as the main image
                        if !combinedUrls.isEmpty {
                            updatedItem.imageURL = combinedUrls[0]
                        }
                        
                        // Save the updated item
                        MerchService.shared.updateItem(updatedItem) { success in
                            DispatchQueue.main.async {
                                self.isUploading = false
                                if success {
                                    self.dismiss()
                                } else {
                                    self.errorMessage = NSLocalizedString("Failed to save changes", comment: "Error message when saving merchandise item fails")
                                    self.showError = true
                                }
                            }
                        }
                        
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = NSLocalizedString("Error uploading images: \(error.localizedDescription)", comment: "Error message when image upload fails")
                        self.showError = true
                    }
                }
            }
        } else {
            // No new images, just update the item with existing images
            updatedItem.imageUrls = existingImageUrls
            if !existingImageUrls.isEmpty {
                updatedItem.imageURL = existingImageUrls[0]
            }
            
            MerchService.shared.updateItem(updatedItem) { success in
                DispatchQueue.main.async {
                    self.isUploading = false
                    if success {
                        self.dismiss()
                    } else {
                        self.errorMessage = NSLocalizedString("Failed to save changes", comment: "Error message when saving merchandise item fails")
                        self.showError = true
                    }
                }
            }
        }
    }

    private func deleteItem() {
        isUploading = true
        
        MerchService.shared.deleteItem(item) { success in
            DispatchQueue.main.async {
                self.isUploading = false
                
                if success {
                    self.dismiss()
                } else {
                    self.errorMessage = NSLocalizedString("Failed to delete item", comment: "Error message when deleting merchandise item fails")
                    self.showError = true
                }
            }
        }
    }
}
