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
    @State private var currentCacheSize = NSLocalizedString("calculating", comment: "Text shown while calculating cache size")
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
                        Text(NSLocalizedString("current_cache_size", comment: "Label for current cache size display"))
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(currentCacheSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(NSLocalizedString("clear_now", comment: "Button to clear cache immediately")) {
                        showClearConfirmation = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .disabled(isClearing)
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("cache_status", comment: "Header for cache status section"))
            }
            
            Section {
                Picker(NSLocalizedString("maximum_cache_size", comment: "Picker label for maximum cache size setting"), selection: $selectedCacheSize) {
                    ForEach(cacheSizeOptions, id: \.self) { size in
                        Text("\(size) MB").tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedCacheSize) {
                    saveCacheSettings()
                }
            } header: {
                Text(NSLocalizedString("storage_limit", comment: "Header for storage limit section"))
            } footer: {
                Text(NSLocalizedString("cache_limit_description", comment: "Description of cache limit behavior"))
            }
            
            Section {
                Picker(NSLocalizedString("auto_cleanup_period", comment: "Picker label for automatic cleanup period"), selection: $autoCleanupPeriod) {
                    ForEach(cleanupPeriodOptions, id: \.self) { days in
                        if days == 7 {
                            Text(NSLocalizedString("weekly", comment: "Weekly cleanup period option")).tag(days)
                        } else if days == 14 {
                            Text(NSLocalizedString("every_2_weeks", comment: "Every 2 weeks cleanup period option")).tag(days)
                        } else {
                            Text(NSLocalizedString("monthly", comment: "Monthly cleanup period option")).tag(days)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: autoCleanupPeriod) {
                    saveCacheSettings()
                }
            } header: {
                Text(NSLocalizedString("automatic_cleanup", comment: "Header for automatic cleanup section"))
            } footer: {
                Text(String(format: NSLocalizedString("cleanup_description", comment: "Description of automatic cleanup with placeholder for period"), autoCleanupPeriod == 7 ? NSLocalizedString("week", comment: "Week period") : autoCleanupPeriod == 14 ? NSLocalizedString("2_weeks", comment: "2 weeks period") : NSLocalizedString("month", comment: "Month period")))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("what_is_cached", comment: "Title asking what data is cached"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(NSLocalizedString("cached_data_list", comment: "List of data types that are cached"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("about_cache", comment: "Header for about cache section"))
            }
        }
        .navigationTitle(NSLocalizedString("cache_storage", comment: "Navigation title for cache and storage settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCacheSettings()
            calculateCacheSize()
        }
        .alert(NSLocalizedString("clear_cache", comment: "Alert title for clearing cache"), isPresented: $showClearConfirmation) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("clear", comment: "Clear button"), role: .destructive) {
                clearCache()
            }
        } message: {
            Text(NSLocalizedString("clear_cache_warning", comment: "Warning message when clearing cache"))
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
