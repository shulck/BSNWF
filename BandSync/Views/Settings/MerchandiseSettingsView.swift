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
                Toggle("Low Stock Notifications".localized, isOn: $lowStockNotificationsEnabled)
                    .onChange(of: lowStockNotificationsEnabled) {
                        saveLowStockSettings()
                    }
                
                if lowStockNotificationsEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You'll get notified when items are running low".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Notifications".localized)
            }
            
            if lowStockNotificationsEnabled {
                Section {
                    Picker("Threshold".localized, selection: $lowStockThreshold) {
                        ForEach(thresholdOptions, id: \.self) { threshold in
                            Text(String(format: "%d items or less".localized, threshold)).tag(threshold)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: lowStockThreshold) {
                        saveLowStockSettings()
                    }
                } header: {
                    Text("Low Stock Threshold".localized)
                } footer: {
                    Text(String(format: "You'll receive notifications when any merchandise item has %d or fewer items in stock.".localized, lowStockThreshold))
                }
            }
        }
        .navigationTitle("Merchandise".localized)
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
