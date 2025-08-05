import SwiftUI

struct EditSaleView: View {
    @Environment(\.dismiss) var dismiss
    let sale: MerchSale
    let item: MerchItem

    @State private var size: String
    @State private var quantity: Int
    @State private var channel: MerchSaleChannel
    @State private var isUpdating = false
    @State private var showDeleteConfirmation = false
    @State private var isGift: Bool

    init(sale: MerchSale, item: MerchItem) {
        self.sale = sale
        self.item = item
        _size = State(initialValue: sale.size)
        _quantity = State(initialValue: sale.quantity)
        _channel = State(initialValue: sale.channel)
        _isGift = State(initialValue: sale.channel == .gift)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Item information", comment: "Header for merchandise item information section"))) {
                    HStack {
                        Text(NSLocalizedString("Item", comment: "Label for merchandise item name"))
                        Spacer()
                        Text(item.name)
                            .foregroundColor(.secondary)
                    }

                    if let subcategory = item.subcategory {
                        HStack {
                            Text(NSLocalizedString("Category", comment: "Label for merchandise category"))
                            Spacer()
                            Text("\(item.category.localizedName) • \(subcategory.localizedName)")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text(NSLocalizedString("Category", comment: "Label for merchandise category"))
                            Spacer()
                            Text(item.category.localizedName)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Price", comment: "Label for merchandise item price"))
                        Spacer()
                        Text("\(Int(item.price)) EUR")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(NSLocalizedString("Sale date", comment: "Label for merchandise sale date"))
                        Spacer()
                        Text(formattedDate)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text(NSLocalizedString("Sale details", comment: "Header for merchandise sale details section"))) {
                    // Only show size picker for clothing items
                    if item.category == .clothing {
                        Picker(NSLocalizedString("Size", comment: "Label for merchandise size picker"), selection: $size) {
                            ForEach(["S", "M", "L", "XL", "XXL"], id: \.self) { size in
                                Text(size)
                            }
                        }
                    }

                    Stepper(String.localizedStringWithFormat(NSLocalizedString("Quantity: %d", comment: "Stepper label for merchandise quantity with count"), quantity), value: $quantity, in: 1...999)

                    Toggle(NSLocalizedString("This is a gift", comment: "Toggle label to mark sale as gift"), isOn: $isGift)
                        .onChange(of: isGift) {
                            if isGift {
                                channel = .gift
                            } else if channel == .gift {
                                channel = .concert
                            }
                        }

                    if !isGift {
                        Picker(NSLocalizedString("Sales channel", comment: "Label for merchandise sales channel picker"), selection: $channel) {
                            ForEach(MerchSaleChannel.allCases.filter { $0 != .gift }) {
                                Text($0.localizedName).tag($0)
                            }
                        }
                    }

                    HStack {
                        Text(NSLocalizedString("Total", comment: "Label for merchandise sale total amount"))
                        Spacer()
                        if isGift {
                            Text(NSLocalizedString("Gift", comment: "Label indicating item is a gift"))
                                .bold()
                                .foregroundColor(.green)
                        } else {
                            Text("\(totalAmount, specifier: "%.2f") EUR")
                                .bold()
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("Delete sale", comment: "Button to delete merchandise sale"))
                            Spacer()
                        }
                    }
                }
            }
            .alert(NSLocalizedString("Delete sale?", comment: "Alert title for deleting merchandise sale"), isPresented: $showDeleteConfirmation) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button in delete confirmation alert"), role: .cancel) {}
                Button(NSLocalizedString("Delete", comment: "Delete button in delete confirmation alert"), role: .destructive) {
                    deleteSale()
                }
            }
            .navigationTitle(NSLocalizedString("Edit sale", comment: "Navigation title for edit merchandise sale screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Button to save merchandise sale changes")) {
                        updateSale()
                    }
                    .disabled(isUpdating || !isChanged)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Button to cancel merchandise sale editing"), role: .cancel) {
                        dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if isUpdating {
                        ProgressView(NSLocalizedString("Updating...", comment: "Progress indicator when updating merchandise sale"))
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            )
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: sale.date)
    }

    private var totalAmount: Double {
        return Double(quantity) * item.price
    }

    private var isChanged: Bool {
        return size != sale.size ||
               quantity != sale.quantity ||
               channel != sale.channel
    }

    private func updateSale() {
        isUpdating = true

        // First cancel the old sale
        MerchService.shared.cancelSale(sale, item: item) { success in
            if success {
                // Then create a new one with updated data
                // If it's a gift, forcibly set the channel to gift
                let finalChannel = isGift ? MerchSaleChannel.gift : channel
                MerchService.shared.recordSale(item: item, size: size, quantity: quantity, channel: finalChannel)
                isUpdating = false
                dismiss()
            } else {
                isUpdating = false
                // Here you can add an error notification
            }
        }
    }

    private func deleteSale() {
        isUpdating = true
        MerchService.shared.cancelSale(sale, item: item) { success in
            isUpdating = false
            if success {
                dismiss()
            }
        }
    }
}

