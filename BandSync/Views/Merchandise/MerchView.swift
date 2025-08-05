//  MerchView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct MerchView: View {
    @StateObject private var merchService = MerchService.shared
    @State private var showAdd = false
    @State private var showDrafts = false
    @State private var showAnalytics = false
    @State private var selectedCategory: MerchCategory? = nil
    @State private var searchText = ""
    @State private var showLowStockAlert = false
    @State private var showingExportOptions = false
    @State private var exportedData: Foundation.Data?
    @State private var showingShareSheet = false
    @State private var isGridView = false
    @State private var showingSortOptions = false
    @State private var sortOption: SortOption = .name
    @State private var showFilterPopover = false
    @Environment(\.colorScheme) private var colorScheme
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case nameDesc = "Name (Z-A)"
        case price = "Price (Low to High)"
        case priceDesc = "Price (High to Low)"
        case stock = "Stock (Low to High)"
        case stockDesc = "Stock (High to Low)"
        case newest = "Newest First"
        case oldest = "Oldest First"
        
        var localizedName: String {
            switch self {
            case .name: return NSLocalizedString("Name", comment: "Sort option by name A-Z")
            case .nameDesc: return NSLocalizedString("Name (Z-A)", comment: "Sort option by name Z-A")
            case .price: return NSLocalizedString("Price (Low to High)", comment: "Sort option by price low to high")
            case .priceDesc: return NSLocalizedString("Price (High to Low)", comment: "Sort option by price high to low")
            case .stock: return NSLocalizedString("Stock (Low to High)", comment: "Sort option by stock low to high")
            case .stockDesc: return NSLocalizedString("Stock (High to Low)", comment: "Sort option by stock high to low")
            case .newest: return NSLocalizedString("Newest First", comment: "Sort option by newest first")
            case .oldest: return NSLocalizedString("Oldest First", comment: "Sort option by oldest first")
            }
        }
    }

    // Filtered items based on search and categories
    private var filteredItems: [MerchItem] {
        var items = merchService.items

        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        // Filter by search query
        if !searchText.isEmpty {
            items = items.filter { item in
                // Разбиваем сложное выражение на отдельные условия для облегчения проверки типа
                let nameMatch = item.name.lowercased().contains(searchText.lowercased())
                let descMatch = item.description.lowercased().contains(searchText.lowercased())
                let categoryMatch = item.category.rawValue.lowercased().contains(searchText.lowercased())
                
                let subcategoryMatch: Bool
                if let subcategory = item.subcategory?.rawValue.lowercased() {
                    subcategoryMatch = subcategory.contains(searchText.lowercased())
                } else {
                    subcategoryMatch = false
                }
                
                let skuMatch: Bool
                if let sku = item.sku?.lowercased() {
                    skuMatch = sku.contains(searchText.lowercased())
                } else {
                    skuMatch = false
                }
                
                // Объединяем результаты поиска
                return nameMatch || descMatch || categoryMatch || subcategoryMatch || skuMatch
            }
        }
        
        // Sort items
        return sortItems(items)
    }
    
    // Sort items based on selected option
    private func sortItems(_ items: [MerchItem]) -> [MerchItem] {
        switch sortOption {
        case .name:
            return items.sorted(by: { item1, item2 in
                item1.name < item2.name
            })
        case .nameDesc:
            return items.sorted(by: { item1, item2 in
                item1.name > item2.name
            })
        case .price:
            return items.sorted(by: { item1, item2 in
                item1.price < item2.price
            })
        case .priceDesc:
            return items.sorted(by: { item1, item2 in
                item1.price > item2.price
            })
        case .stock:
            return items.sorted(by: { item1, item2 in
                item1.totalStock < item2.totalStock
            })
        case .stockDesc:
            return items.sorted(by: { item1, item2 in
                item1.totalStock > item2.totalStock
            })
        case .newest:
            return items.sorted(by: { item1, item2 in
                // Используем updatedAt вместо createdAt, проверяя на nil
                let date1 = item1.updatedAt ?? Date(timeIntervalSince1970: 0)
                let date2 = item2.updatedAt ?? Date(timeIntervalSince1970: 0)
                return date1 > date2
            })
        case .oldest:
            return items.sorted(by: { item1, item2 in
                // Используем updatedAt вместо createdAt, проверяя на nil
                let date1 = item1.updatedAt ?? Date(timeIntervalSince1970: 0)
                let date2 = item2.updatedAt ?? Date(timeIntervalSince1970: 0)
                return date1 < date2
            })
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
                
                VStack(spacing: 0) {
                    // Профессиональная горизонтальная прокрутка категорий
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            categoryButton(title: NSLocalizedString("All", comment: "Category filter for all merchandise"), icon: "tshirt.fill", category: nil)

                            ForEach(MerchCategory.allCases) { category in
                                categoryButton(
                                    title: category.localizedName,
                                    icon: category.icon,
                                    category: category
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .background(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                    )

                    // Item counter and controls
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("ITEMS", comment: "Header label for items count"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                
                            Text("\(filteredItems.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }

                        Spacer()
                        
                        // Low stock and view toggles
                        HStack(spacing: 10) {
                            if !merchService.lowStockItems.isEmpty {
                                // Low stock items information
                                Button {
                                    showLowStockItems()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        
                                        Text("\(merchService.lowStockItems.count)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                                }
                            }
                            
                            // Sort button
                            Button(action: {
                                showingSortOptions = true
                            }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                            .confirmationDialog(NSLocalizedString("Sort By", comment: "Title for sort options dialog"), isPresented: $showingSortOptions) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(option.localizedName) {
                                        sortOption = option
                                    }
                                }
                                Button(NSLocalizedString("Cancel", comment: "Cancel button in sort dialog"), role: .cancel) {}
                            }
                            
                            // Grid/List toggle
                            Button(action: {
                                isGridView.toggle()
                            }) {
                                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e").opacity(0.8) : .white.opacity(0.8))
                    )

                    if merchService.isLoading {
                        // Loading indicator
                        Spacer()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text(NSLocalizedString("Loading merchandise items...", comment: "Loading message for merchandise items"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Spacer()
                    } else if filteredItems.isEmpty {
                        // Empty list state
                        Spacer()
                        
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "bag")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }
                            
                            Text(searchText.isEmpty
                                ? NSLocalizedString("No items in selected category", comment: "Message when no items in selected category")
                                : NSLocalizedString("No items matching '\(searchText)'", comment: "Message when no items match search"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)

                            if AppState.shared.hasEditPermission(for: .merchandise) {
                                Button(action: {
                                    showAdd = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text(NSLocalizedString("Add New Item", comment: "Button to add new merchandise item"))
                                    }
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 30)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Spacer()
                    } else {
                        // Items list or grid
                        if isGridView {
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                    ForEach(filteredItems) { item in
                                        NavigationLink(destination: MerchDetailView(item: item)) {
                                            MerchItemGridCell(item: item)
                                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                                .padding(.bottom, 20)
                            }
                        } else {
                            List {
                                ForEach(filteredItems) { item in
                                    NavigationLink(destination: MerchDetailView(item: item)) {
                                        MerchItemRow(item: item, colorScheme: colorScheme)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .background(colorScheme == .dark ? Color(hex: "121212") : Color(hex: "f8f9fa"))
                        }
                    }
                }
                
                // Floating Action Button for adding items
                if AppState.shared.hasEditPermission(for: .merchandise) && !merchService.isLoading && !filteredItems.isEmpty {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                showAdd = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Merch", comment: "Navigation title for merchandise screen"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: NSLocalizedString("Search items", comment: "Search placeholder for merchandise items"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if AppState.shared.hasEditPermission(for: .merchandise) {
                            Button {
                                showAdd = true
                            } label: {
                                Label(NSLocalizedString("Add item", comment: "Menu item to add merchandise"), systemImage: "plus")
                            }
                            
                            Button {
                                showDrafts = true
                            } label: {
                                Label(NSLocalizedString("Saved drafts", comment: "Menu item to view saved drafts"), systemImage: "tray.and.arrow.down")
                            }
                        }

                        Button {
                            showAnalytics = true
                        } label: {
                            Label(NSLocalizedString("Sales analytics", comment: "Menu item to view sales analytics"), systemImage: "chart.bar")
                        }

                        if !merchService.lowStockItems.isEmpty {
                            Button {
                                showLowStockItems()
                            } label: {
                                Label(NSLocalizedString("Show low stock items", comment: "Menu item to show low stock items"), systemImage: "exclamationmark.triangle")
                            }
                        }
                        
                        Button {
                            showingExportOptions = true
                        } label: {
                            Label(NSLocalizedString("Export", comment: "Menu item to export data"), systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !merchService.lowStockItems.isEmpty {
                        HStack(spacing: -8) {
                            Badge(count: merchService.lowStockItems.count, color: .orange)
                                .offset(x: 0, y: -10)
                        }
                    }
                }
            }
            .onAppear {
                if let groupId = AppState.shared.user?.groupId {
                    merchService.fetchItems(for: groupId)
                    merchService.fetchSales(for: groupId)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMerchView()
            }
            .sheet(isPresented: $showDrafts) {
                DraftsView()
            }
            .alert(NSLocalizedString("Low stock items", comment: "Title for low stock alert"), isPresented: $showLowStockAlert) {
                Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("There are %d items with stock below threshold.", comment: "Low stock alert message with count").replacingOccurrences(of: "%d", with: "\(merchService.lowStockItems.count)"))
            }
            .confirmationDialog(NSLocalizedString("Export Options", comment: "Title for export options dialog"), isPresented: $showingExportOptions) {
                Button(NSLocalizedString("Export Inventory", comment: "Button to export inventory")) {
                    exportInventory()
                }
                
                Button(NSLocalizedString("Export Sales", comment: "Button to export sales")) {
                    exportSales()
                }
                
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
            }
            .sheet(isPresented: $showingShareSheet) {
                if let exportedData = exportedData {
                    MerchShareSheet(data: exportedData, filename: "merch_export.csv")
                }
            }
    }

    // Профессиональная кнопка категории
    private func categoryButton(title: String, icon: String, category: MerchCategory?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .frame(width: 90, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedCategory == category ?
                          LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "f8f9fa"),
                                colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "f8f9fa")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            )
            .shadow(
                color: selectedCategory == category ? Color.blue.opacity(0.3) : Color.black.opacity(0.05),
                radius: selectedCategory == category ? 8 : 4,
                x: 0,
                y: selectedCategory == category ? 4 : 2
            )
            .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedCategory)
    }

    // Show low stock items
    private func showLowStockItems() {
        // Create temporary list for comparison
        let lowStockItemIds = Set(merchService.lowStockItems.compactMap { $0.id })

        // Determine low stock items in current view
        let lowStockItemsInCurrentView = filteredItems.filter { item in
            if let id = item.id {
                return lowStockItemIds.contains(id)
            }
            return false
        }

        // If no low stock items in current view,
        // show separate alert with information
        if lowStockItemsInCurrentView.isEmpty {
            showLowStockAlert = true
        } else {
            // Otherwise reset filters and set new search to display only low stock items
            selectedCategory = nil
            searchText = "low_stock_filter"

            // Delay for applying filters
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.searchText = ""  // Reset search query
                
                // Set sort by stock (low to high)
                self.sortOption = .stock
            }
        }
    }
    
    // Export inventory to CSV
    private func exportInventory() {
        if let data = ImportExportService.shared.exportItemsToCSV(items: merchService.items) {
            self.exportedData = data
            self.showingShareSheet = true
        }
    }
    
    // Export sales to CSV
    private func exportSales() {
        if let data = ImportExportService.shared.exportSalesToCSV(sales: merchService.sales, items: merchService.items) {
            self.exportedData = data
            self.showingShareSheet = true
        }
    }
}

// Badge for notifications
struct Badge: View {
    let count: Int
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Structure for item grid cell

struct MerchItemGridCell: View {
    let item: MerchItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            // Item image or category icon
            ZStack(alignment: .topTrailing) {
                MerchImageView(imageUrl: item.imageURL ?? "", item: item)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if item.isLowStock {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                }
            }
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(Int(item.price)) EUR")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("Stock:", comment: "Label for stock information"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Text("\(item.totalStock)")
                            .font(.caption)
                            .foregroundColor(getStockColor(item))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(getStockBackgroundColor(item))
                    )
                }
                
                Text(item.category.localizedName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(colorScheme == .dark ? Color(hex: "1e1e1e") : Color.white)
        .cornerRadius(16)
    }
    
    private func getStockColor(_ item: MerchItem) -> Color {
        if item.totalStock == 0 {
            return .red
        } else if item.isLowStock {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getStockBackgroundColor(_ item: MerchItem) -> Color {
        if item.totalStock == 0 {
            return .red.opacity(0.1)
        } else if item.isLowStock {
            return .orange.opacity(0.1)
        } else {
            return .green.opacity(0.1)
        }
    }
}

// MARK: - Structure for item row

struct MerchItemRow: View {
    let item: MerchItem
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Item image or category icon
            ZStack {
                MerchImageView(imageUrl: item.imageURL ?? "", item: item)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if item.isLowStock {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 18, height: 18)
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }

            // Item information
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text("\(item.category.localizedName) \(item.subcategory != nil ? "• \(item.subcategory!.localizedName)" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                // Stock indicator - show depending on category
                if item.category == .clothing {
                    // For clothing show sizes
                    HStack(spacing: 5) {
                        Text(NSLocalizedString("Sizes:", comment: "Label for sizes information"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        sizeIndicator("S", quantity: item.stock.S, lowThreshold: item.lowStockThreshold)
                        sizeIndicator("M", quantity: item.stock.M, lowThreshold: item.lowStockThreshold)
                        sizeIndicator("L", quantity: item.stock.L, lowThreshold: item.lowStockThreshold)
                        sizeIndicator("XL", quantity: item.stock.XL, lowThreshold: item.lowStockThreshold)
                        sizeIndicator("XXL", quantity: item.stock.XXL, lowThreshold: item.lowStockThreshold)
                    }
                } else {
                    // For other categories show total quantity
                    HStack(spacing: 5) {
                        Text(NSLocalizedString("Quantity:", comment: "Label for quantity information"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        // Use sizeIndicator to display quantity with same style
                        Text("\(item.totalStock)")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                item.totalStock == 0 ? Color.red.opacity(0.2) :
                                    item.isLowStock ? Color.orange.opacity(0.2) :
                                        Color.green.opacity(0.2)
                            )
                            .foregroundColor(
                                item.totalStock == 0 ? .red :
                                    item.isLowStock ? .orange :
                                        .green
                            )
                            .cornerRadius(3)
                    }
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(item.price)) EUR")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(String.localizedStringWithFormat(NSLocalizedString("Total: %d", comment: "Total stock count"), item.totalStock))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                colorScheme == .dark ?
                                    Color(hex: "252525") :
                                    Color(hex: "f0f0f0")
                            )
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : Color.white)
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    // Size availability indicator
    private func sizeIndicator(_ size: String, quantity: Int, lowThreshold: Int) -> some View {
        Text(size)
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                quantity == 0 ? Color.red.opacity(0.2) :
                    quantity <= lowThreshold ? Color.orange.opacity(0.2) :
                        Color.green.opacity(0.2)
            )
            .foregroundColor(
                quantity == 0 ? .red :
                    quantity <= lowThreshold ? .orange :
                        .green
            )
            .cornerRadius(3)
    }
}

// Drafts View
struct DraftsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var drafts: [MerchItem] = []
    @State private var showConfirmation = false
    @State private var selectedDraft: MerchItem?
    @State private var showAddView = false
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            VStack {
                    if drafts.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                            
                            Text(NSLocalizedString("No Saved Drafts", comment: "Message when no drafts are saved"))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                            
                            Text(NSLocalizedString("Drafts you save while creating new merchandise will appear here", comment: "Information message about drafts"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }
                        
                        Spacer()
                    } else {
                        List {
                            ForEach(drafts.indices, id: \.self) { index in
                                let draft = drafts[index]
                                Button {
                                    selectedDraft = drafts[index]
                                    showConfirmation = true
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f0f0f0"))
                                                .frame(width: 48, height: 48)
                                            
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 18))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(draft.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.9)
                                            
                                            HStack {
                                                Text(draft.category.localizedName)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.9)
                                                
                                                Circle()
                                                    .fill(Color.secondary.opacity(0.5))
                                                    .frame(width: 4, height: 4)
                                                
                                                Text("\(draft.price, specifier: "%.2f") EUR")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.9)
                                            }
                                            
                                            if draft.totalStock > 0 {
                                                Text(String.localizedStringWithFormat(NSLocalizedString("Stock: %d", comment: "Stock count in draft"), draft.totalStock))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : Color.white)
                                    )
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteDraft(at: index)
                                    } label: {
                                        Label(NSLocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Saved Drafts", comment: "Navigation title for saved drafts"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !drafts.isEmpty {
                        Button(NSLocalizedString("Clear All", comment: "Clear all button")) {
                            UserDefaults.standard.removeObject(forKey: "merch_item_drafts")
                            drafts = []
                        }
                    }
                }
            }
            .onAppear {
                loadDrafts()
            }
            .alert(NSLocalizedString("Load Draft?", comment: "Alert title for loading draft"), isPresented: $showConfirmation) {
                Button(NSLocalizedString("Edit", comment: "Edit button")) {
                    // Load draft functionality can be implemented here
                    showConfirmation = false
                    showAddView = true
                }
                
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                    selectedDraft = nil
                    showConfirmation = false
                }
            } message: {
                Text(NSLocalizedString("Do you want to load and edit this draft?", comment: "Confirmation message for loading draft"))
            }
    }
    
    private func loadDrafts() {
        if let draftsData = UserDefaults.standard.array(forKey: "merch_item_drafts") as? [Data] {
            let decoder = JSONDecoder()
            drafts = draftsData.compactMap { data in
                try? decoder.decode(MerchItem.self, from: data)
            }
        }
    }
    
    private func deleteDraft(at index: Int) {
        if var draftsData = UserDefaults.standard.array(forKey: "merch_item_drafts") as? [Data] {
            if index < draftsData.count {
                draftsData.remove(at: index)
                UserDefaults.standard.set(draftsData, forKey: "merch_item_drafts")
                loadDrafts()
            }
        }
    }
}

