//
//  SellMerchView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI
import os.log

struct SellMerchView: View {
    @Environment(\.dismiss) var dismiss
    let item: MerchItem
    private let logger = Logger(subsystem: "com.bandsync.app", category: "SellMerchView")

    @State private var size = "one_size"
    @State private var quantity = 1
    @State private var channel: MerchSaleChannel = .concert
    @State private var isGift = false

    var body: some View {
        NavigationView {
            Form {
                // Show sizes only for clothing
                if item.category == .clothing {
                    Section(NSLocalizedString("Size", comment: "Section header for merchandise size selection")) {
                        Picker(NSLocalizedString("Size", comment: "Picker label for merchandise size selection"), selection: $size) {
                            // Show only sizes that are in stock
                            if item.stock.S > 0 {
                                Text(String.localizedStringWithFormat(NSLocalizedString("S (%d available)", comment: "Size S with available quantity"), item.stock.S)).tag("S")
                            }
                            if item.stock.M > 0 {
                                Text(String.localizedStringWithFormat(NSLocalizedString("M (%d available)", comment: "Size M with available quantity"), item.stock.M)).tag("M")
                            }
                            if item.stock.L > 0 {
                                Text(String.localizedStringWithFormat(NSLocalizedString("L (%d available)", comment: "Size L with available quantity"), item.stock.L)).tag("L")
                            }
                            if item.stock.XL > 0 {
                                Text(String.localizedStringWithFormat(NSLocalizedString("XL (%d available)", comment: "Size XL with available quantity"), item.stock.XL)).tag("XL")
                            }
                            if item.stock.XXL > 0 {
                                Text(String.localizedStringWithFormat(NSLocalizedString("XXL (%d available)", comment: "Size XXL with available quantity"), item.stock.XXL)).tag("XXL")
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if !hasAvailableSizes {
                            Text(NSLocalizedString("No Sizes Available", comment: "Message when no sizes are available for clothing"))
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                } else {
                    // For non-clothing show available quantity
                    Section(NSLocalizedString("Stock", comment: "Section header for merchandise stock information")) {
                        HStack {
                            Text(NSLocalizedString("Available quantity:", comment: "Label for available quantity"))
                            Spacer()
                            Text("\(item.totalStock)")
                                .foregroundColor(item.totalStock > 0 ? .green : .red)
                                .fontWeight(.semibold)
                        }
                        
                        if item.totalStock == 0 {
                            Text(NSLocalizedString("Item Out Of Stock", comment: "Message when item is out of stock"))
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Section(NSLocalizedString("Quantity", comment: "Section header for merchandise quantity selection")) {
                    // FIXED: Safe range for Stepper
                    let safeRange = maxAvailableQuantity > 0 ? 1...maxAvailableQuantity : 0...0
                    
                    if maxAvailableQuantity > 0 {
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("Quantity: %d", comment: "Stepper label for quantity with count"), quantity), value: $quantity, in: safeRange)
                        
                        Text(String.localizedStringWithFormat(NSLocalizedString("Maximum available: %d", comment: "Information about maximum available quantity"), maxAvailableQuantity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Text(String.localizedStringWithFormat(NSLocalizedString("Quantity: %d", comment: "Quantity label with count"), quantity))
                            Spacer()
                            Text(NSLocalizedString("Out Of Stock", comment: "Out of stock message"))
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Section(NSLocalizedString("Sale Type", comment: "Section header for sale type selection")) {
                    Toggle(NSLocalizedString("This is a gift", comment: "Toggle label to mark sale as gift"), isOn: $isGift)
                        .disabled(maxAvailableQuantity == 0) // Disable if no stock
                        .onChange(of: isGift) { oldValue, newValue in
                            if newValue {
                                channel = .gift
                            } else if channel == .gift {
                                channel = .concert
                            }
                        }

                    if !isGift {
                        Picker(NSLocalizedString("Sales channel", comment: "Picker label for sales channel selection"), selection: $channel) {
                            ForEach(MerchSaleChannel.allCases.filter { $0 != .gift }, id: \.self) { channel in
                                Text(channel.localizedName).tag(channel)
                            }
                        }
                        .disabled(maxAvailableQuantity == 0) // Disable if no stock
                    }
                }
                
                // Show sale total information
                Section(NSLocalizedString("Total", comment: "Section header for sale total")) {
                    if !isGift {
                        HStack {
                            Text(NSLocalizedString("Total", comment: "Label for total amount"))
                            Spacer()
                            Text("\(Double(quantity) * item.price, specifier: "%.2f") EUR")
                                .bold()
                        }
                    } else {
                        HStack {
                            Text(NSLocalizedString("Total", comment: "Label for total amount"))
                            Spacer()
                            Text(NSLocalizedString("Gift", comment: "Gift label for total"))
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle(isGift ? NSLocalizedString("Gift item", comment: "Navigation title when gifting item") : NSLocalizedString("Sale", comment: "Navigation title for sale screen"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isGift ? NSLocalizedString("Gift", comment: "Button to confirm gift") : NSLocalizedString("Confirm", comment: "Button to confirm sale")) {
                        recordSale()
                    }
                    .disabled(!canSell)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Button to cancel sale"), role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasAvailableSizes: Bool {
        if item.category != .clothing { return true }
        return item.stock.S > 0 || item.stock.M > 0 || item.stock.L > 0 || item.stock.XL > 0 || item.stock.XXL > 0
    }
    
    private var maxAvailableQuantity: Int {
        let quantity: Int
        
        if item.category == .clothing {
            switch size {
            case "S": quantity = item.stock.S
            case "M": quantity = item.stock.M
            case "L": quantity = item.stock.L
            case "XL": quantity = item.stock.XL
            case "XXL": quantity = item.stock.XXL
            default: quantity = 0
            }
        } else {
            quantity = item.totalStock
        }
        
        // FIXED: Add debug logging
        logger.debug("maxAvailableQuantity for \(item.name, privacy: .public), size: \(size, privacy: .public) = \(quantity)")
        
        return max(0, quantity) // Ensure we don't return negative number
    }
    
    private var canSell: Bool {
        let canSellResult = maxAvailableQuantity >= quantity && quantity > 0 && maxAvailableQuantity > 0
        logger.debug("canSell: maxAvailable=\(maxAvailableQuantity), quantity=\(quantity), result=\(canSellResult, privacy: .public)")
        return canSellResult
    }
    
    // MARK: - Methods
    
    private func setupInitialValues() {
        logger.debug("Setting up initial values for item: \(item.name, privacy: .public)")
        
        if item.category == .clothing {
            // Find first available size
            var foundSize = false
            
            if item.stock.S > 0 && !foundSize {
                size = "S"
                foundSize = true
            } else if item.stock.M > 0 && !foundSize {
                size = "M"
                foundSize = true
            } else if item.stock.L > 0 && !foundSize {
                size = "L"
                foundSize = true
            } else if item.stock.XL > 0 && !foundSize {
                size = "XL"
                foundSize = true
            } else if item.stock.XXL > 0 && !foundSize {
                size = "XXL"
                foundSize = true
            }
            
            if !foundSize {
                logger.warning("No available sizes found for clothing item: \(item.name, privacy: .public)")
                size = "S" // Set default size even if not available
            }
        } else {
            // For non-clothing always use one_size
            size = "one_size"
        }
        
        // FIXED: Safe quantity setup
        let maxQuantity = maxAvailableQuantity
        if maxQuantity > 0 {
            quantity = min(quantity, maxQuantity)
        } else {
            quantity = 0
            logger.warning("No stock available for item: \(item.name, privacy: .public), size: \(size, privacy: .public)")
        }
        
        logger.debug("Initial setup complete: size=\(size, privacy: .public), quantity=\(quantity), maxAvailable=\(maxQuantity)")
    }
    
    private func recordSale() {
        // FIXED: Additional check before recording sale
        guard canSell else {
            logger.error("Cannot record sale: insufficient stock or invalid quantity")
            return
        }
        
        let finalChannel = isGift ? MerchSaleChannel.gift : channel
        let finalSize = item.category == .clothing ? size : "one_size"
        
        logger.info("Recording sale: item=\(item.name, privacy: .public), size=\(finalSize, privacy: .public), quantity=\(quantity), channel=\(finalChannel.rawValue, privacy: .public)")
        
        // FIXED: Additional validation before calling service
        guard quantity > 0 && quantity <= maxAvailableQuantity else {
            logger.error("Invalid quantity: \(quantity), max available: \(maxAvailableQuantity)")
            return
        }
        
        MerchService.shared.recordSale(
            item: item,
            size: finalSize,
            quantity: quantity,
            channel: finalChannel
        )
        dismiss()
    }
}
