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
                    Section("Size".localized) {
                        Picker("Size".localized, selection: $size) {
                            // Show only sizes that are in stock
                            if item.stock.S > 0 {
                                Text(String.localizedStringWithFormat("S (%d available)".localized, item.stock.S)).tag("S")
                            }
                            if item.stock.M > 0 {
                                Text(String.localizedStringWithFormat("M (%d available)".localized, item.stock.M)).tag("M")
                            }
                            if item.stock.L > 0 {
                                Text(String.localizedStringWithFormat("L (%d available)".localized, item.stock.L)).tag("L")
                            }
                            if item.stock.XL > 0 {
                                Text(String.localizedStringWithFormat("XL (%d available)".localized, item.stock.XL)).tag("XL")
                            }
                            if item.stock.XXL > 0 {
                                Text(String.localizedStringWithFormat("XXL (%d available)".localized, item.stock.XXL)).tag("XXL")
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if !hasAvailableSizes {
                            Text("No Sizes Available".localized)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                } else {
                    // For non-clothing show available quantity
                    Section("Stock".localized) {
                        HStack {
                            Text("Available quantity:".localized)
                            Spacer()
                            Text("\(item.totalStock)")
                                .foregroundColor(item.totalStock > 0 ? .green : .red)
                                .fontWeight(.semibold)
                        }
                        
                        if item.totalStock == 0 {
                            Text("Item Out Of Stock".localized)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Section("Quantity".localized) {
                    // FIXED: Safe range for Stepper
                    let safeRange = maxAvailableQuantity > 0 ? 1...maxAvailableQuantity : 0...0
                    
                    if maxAvailableQuantity > 0 {
                        Stepper(String.localizedStringWithFormat("Quantity: %d".localized, quantity), value: $quantity, in: safeRange)
                        
                        Text(String.localizedStringWithFormat("Maximum available: %d".localized, maxAvailableQuantity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Text(String.localizedStringWithFormat("Quantity: %d".localized, quantity))
                            Spacer()
                            Text("Out Of Stock".localized)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }

                Section("Sale Type".localized) {
                    Toggle("This is a gift".localized, isOn: $isGift)
                        .disabled(maxAvailableQuantity == 0) // Disable if no stock
                        .onChange(of: isGift) { oldValue, newValue in
                            if newValue {
                                channel = .gift
                            } else if channel == .gift {
                                channel = .concert
                            }
                        }

                    if !isGift {
                        Picker("Sales channel".localized, selection: $channel) {
                            ForEach(MerchSaleChannel.allCases.filter { $0 != .gift }, id: \.self) { channel in
                                Text(channel.rawValue.localized).tag(channel)
                            }
                        }
                        .disabled(maxAvailableQuantity == 0) // Disable if no stock
                    }
                }
                
                // Show sale total information
                Section("Total".localized) {
                    if !isGift {
                        HStack {
                            Text("Total".localized)
                            Spacer()
                            Text("\(Double(quantity) * item.price, specifier: "%.2f") EUR")
                                .bold()
                        }
                    } else {
                        HStack {
                            Text("Total".localized)
                            Spacer()
                            Text("Gift".localized)
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle(isGift ? "Gift item".localized : "Sale".localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isGift ? "Gift".localized : "Confirm".localized) {
                        recordSale()
                    }
                    .disabled(!canSell)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized, role: .cancel) {
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
