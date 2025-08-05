//
//  MerchandiseSettingsView.swift
//  BandSync
//
//  Created by Developer on 23.06.2025.
//

import SwiftUI

struct MerchandiseSettingsView: View {
    @State private var lowStockNotificationsEnabled = true
    @State private var lowStockThreshold = 10
    
    private let thresholdOptions = [5, 10, 15, 20]
    
    var body: some View {
        List {
            Section {
                Toggle(NSLocalizedString("low_stock_notifications", comment: "Toggle for enabling low stock notifications"), isOn: $lowStockNotificationsEnabled)
                    .onChange(of: lowStockNotificationsEnabled) {
                        saveLowStockSettings()
                    }
                
                if lowStockNotificationsEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(NSLocalizedString("low_stock_notification_description", comment: "Description of low stock notifications"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text(NSLocalizedString("notifications", comment: "Header for notifications section"))
            }
            
            if lowStockNotificationsEnabled {
                Section {
                    Picker(NSLocalizedString("threshold", comment: "Picker label for threshold setting"), selection: $lowStockThreshold) {
                        ForEach(thresholdOptions, id: \.self) { threshold in
                            Text(String(format: NSLocalizedString("items_or_less", comment: "Format string for threshold options with count"), threshold)).tag(threshold)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: lowStockThreshold) {
                        saveLowStockSettings()
                    }
                } header: {
                    Text(NSLocalizedString("low_stock_threshold", comment: "Header for low stock threshold section"))
                } footer: {
                    Text(String(format: NSLocalizedString("threshold_description", comment: "Description of threshold setting with count"), lowStockThreshold))
                }
            }
        }
        .navigationTitle(NSLocalizedString("merchandise", comment: "Navigation title for merchandise settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLowStockSettings()
        }
    }
    
    private func loadLowStockSettings() {
        lowStockNotificationsEnabled = UserDefaults.standard.bool(forKey: "lowStockNotificationsEnabled")
        lowStockThreshold = UserDefaults.standard.integer(forKey: "lowStockThreshold")
        
        if lowStockThreshold == 0 {
            lowStockThreshold = 10
        }
    }
    
    private func saveLowStockSettings() {
        UserDefaults.standard.set(lowStockNotificationsEnabled, forKey: "lowStockNotificationsEnabled")
        UserDefaults.standard.set(lowStockThreshold, forKey: "lowStockThreshold")
    }
}
