//
//  CacheSettingsView.swift
//  BandSync
//
//  Created by Developer on 23.06.2025.
//

import SwiftUI

struct CacheSettingsView: View {
    @State private var selectedCacheSize = 50
    @State private var autoCleanupPeriod = 7
    @State private var currentCacheSize = "Calculating..."
    @State private var showClearConfirmation = false
    @State private var isClearing = false
    
    private let cacheSizeOptions = [25, 50, 100, 200]
    private let cleanupPeriodOptions = [7, 14, 30]
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Cache Size".localized)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(currentCacheSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Clear Now".localized) {
                        showClearConfirmation = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .disabled(isClearing)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Cache Status".localized)
            }
            
            Section {
                Picker("Maximum Cache Size".localized, selection: $selectedCacheSize) {
                    ForEach(cacheSizeOptions, id: \.self) { size in
                        Text("\(size) MB").tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedCacheSize) {
                    saveCacheSettings()
                }
            } header: {
                Text("Storage Limit".localized)
            } footer: {
                Text("When cache exceeds this limit, oldest data will be automatically removed.".localized)
            }
            
            Section {
                Picker("Auto Cleanup Period".localized, selection: $autoCleanupPeriod) {
                    ForEach(cleanupPeriodOptions, id: \.self) { days in
                        if days == 7 {
                            Text("Weekly".localized).tag(days)
                        } else if days == 14 {
                            Text("Every 2 weeks".localized).tag(days)
                        } else {
                            Text("Monthly".localized).tag(days)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: autoCleanupPeriod) {
                    saveCacheSettings()
                }
            } header: {
                Text("Automatic Cleanup".localized)
            } footer: {
                Text(String(format: "Old cached data will be automatically removed every %@.".localized, autoCleanupPeriod == 7 ? "week".localized : autoCleanupPeriod == 14 ? "2 weeks".localized : "month".localized))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What is cached?".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• Merchandise items and sales data\n• Event and setlist information\n• Contact details\n• Financial records\n• Task assignments".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("About Cache".localized)
            }
        }
        .navigationTitle("Cache & Storage".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCacheSettings()
            calculateCacheSize()
        }
        .alert("Clear Cache".localized, isPresented: $showClearConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Clear".localized, role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will remove all cached data. You may experience slower loading times until data is re-cached.".localized)
        }
    }
    
    private func loadCacheSettings() {
        selectedCacheSize = UserDefaults.standard.object(forKey: "maxCacheSize") as? Int ?? 50
        autoCleanupPeriod = UserDefaults.standard.object(forKey: "autoCleanupPeriod") as? Int ?? 7
    }
    
    private func saveCacheSettings() {
        UserDefaults.standard.set(selectedCacheSize, forKey: "maxCacheSize")
        UserDefaults.standard.set(autoCleanupPeriod, forKey: "autoCleanupPeriod")
    }
    
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            let size = getCacheSize()
            DispatchQueue.main.async {
                currentCacheSize = formatBytes(size)
            }
        }
    }
    
    private func getCacheSize() -> Int64 {
        let userDefaults = UserDefaults.standard
        let dictionary = userDefaults.dictionaryRepresentation()
        
        var totalSize: Int64 = 0
        
        for (key, value) in dictionary {
            if key.hasPrefix("cache_") || key.contains("cached_") || key.contains("merch_") {
                if let data = value as? Data {
                    totalSize += Int64(data.count)
                } else if let string = value as? String {
                    totalSize += Int64(string.utf8.count)
                }
            }
        }
        
        return totalSize
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func clearCache() {
        isClearing = true
        
        DispatchQueue.global(qos: .background).async {
            let userDefaults = UserDefaults.standard
            let dictionary = userDefaults.dictionaryRepresentation()
            
            for (key, _) in dictionary {
                if key.hasPrefix("cache_") || key.contains("cached_") || key.contains("merch_item_drafts") {
                    userDefaults.removeObject(forKey: key)
                }
            }
            
            CacheManager.shared.clearAllCache()
            
            DispatchQueue.main.async {
                isClearing = false
                calculateCacheSize()
            }
        }
    }
}
