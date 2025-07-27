//
//  CacheManager.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 10.05.2025.
//

import Foundation
import os.log

class CacheManager {
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.bandsync.app", category: "CacheManager")
    
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50 MB limit
    
    // Cache keys
    private enum CacheKeys {
        static func merchItems(forGroup groupId: String) -> String {
            return "cache_merch_items_\(groupId)"
        }
        
        static func merchSales(forGroup groupId: String) -> String {
            return "cache_merch_sales_\(groupId)"
        }
        
        static let cacheLastCleanup = "cache_last_cleanup"
        static let cacheSize = "cache_size"
    }
    
    private init() {
        // Clean old cache if needed when app starts
        checkAndCleanupCache()
    }
    
    // MARK: - Merchandise Items Cache
    
    func cacheMerchItems(_ items: [MerchItem], forGroupId groupId: String) {
        do {
            let encodedData = try JSONEncoder().encode(items)
            
            // Check if we need to clean up some cache before saving
            updateCacheSize(adding: encodedData.count)
            
            // Save to User Defaults for quick access
            userDefaults.set(encodedData, forKey: CacheKeys.merchItems(forGroup: groupId))
        } catch {
            // Check if this is a Firestore encoding error
            let errorDescription = error.localizedDescription
            if errorDescription.contains("DocumentID") ||
               errorDescription.contains("Firestore") ||
               errorDescription.contains("encodingIsNotSupported") {
                // Silently skip these errors
                return
            }
            
            logger.error("Error caching merch items: \(error.localizedDescription)")
        }
    }
    
    func getCachedMerchItems(forGroupId groupId: String) -> [MerchItem]? {
        guard let encodedData = userDefaults.data(forKey: CacheKeys.merchItems(forGroup: groupId)) else {
            return nil
        }
        
        do {
            let items = try JSONDecoder().decode([MerchItem].self, from: encodedData)
            return items
        } catch {
            logger.error("Error decoding cached merch items: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Merchandise Sales Cache
    
    func cacheMerchSales(_ sales: [MerchSale], forGroupId groupId: String) {
        do {
            let encodedData = try JSONEncoder().encode(sales)
            
            // Check if we need to clean up some cache before saving
            updateCacheSize(adding: encodedData.count)
            
            // Save to User Defaults
            userDefaults.set(encodedData, forKey: CacheKeys.merchSales(forGroup: groupId))
        } catch {
            // Check if this is a Firestore encoding error
            let errorDescription = error.localizedDescription
            if errorDescription.contains("DocumentID") ||
               errorDescription.contains("Firestore") ||
               errorDescription.contains("encodingIsNotSupported") {
                // Silently skip these errors
                return
            }
            
            logger.error("Error caching merch sales: \(error.localizedDescription)")
        }
    }
    
    func getCachedMerchSales(forGroupId groupId: String) -> [MerchSale]? {
        guard let encodedData = userDefaults.data(forKey: CacheKeys.merchSales(forGroup: groupId)) else {
            return nil
        }
        
        do {
            let sales = try JSONDecoder().decode([MerchSale].self, from: encodedData)
            return sales
        } catch {
            logger.error("Error decoding cached merch sales: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    private func updateCacheSize(adding dataSize: Int) {
        let currentCacheSize = userDefaults.integer(forKey: CacheKeys.cacheSize)
        let newCacheSize = currentCacheSize + dataSize
        
        userDefaults.set(newCacheSize, forKey: CacheKeys.cacheSize)
        
        // If cache is getting too large, clean up
        if newCacheSize > maxCacheSize {
            cleanupOldCache()
        }
    }
    
    private func checkAndCleanupCache() {
        let lastCleanup = userDefaults.object(forKey: CacheKeys.cacheLastCleanup) as? Date ?? Date(timeIntervalSince1970: 0)
        let calendar = Calendar.current
        
        // Clean up cache once a week
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), lastCleanup < weekAgo {
            cleanupOldCache()
        }
    }
    
    private func cleanupOldCache() {
        // Get all user defaults keys
        let dictionary = userDefaults.dictionaryRepresentation()
        
        // Find old cache items (older than 30 days)
        var keysToRemove: [String] = []
        
        for (key, _) in dictionary {
            if key.starts(with: "cache_") && key != CacheKeys.cacheLastCleanup && key != CacheKeys.cacheSize {
                keysToRemove.append(key)
            }
        }
        
        // Remove half of the cache items (the oldest ones based on keys)
        let itemsToRemove = keysToRemove.count / 2
        if itemsToRemove > 0 {
            for key in keysToRemove.prefix(itemsToRemove) {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Update cache size (estimate)
        userDefaults.set(maxCacheSize / 2, forKey: CacheKeys.cacheSize)
        
        // Update last cleanup time
        userDefaults.set(Date(), forKey: CacheKeys.cacheLastCleanup)
    }
    
    // Clear all cached data
    func clearAllCache() {
        let dictionary = userDefaults.dictionaryRepresentation()
        
        for (key, _) in dictionary {
            if key.starts(with: "cache_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        userDefaults.set(0, forKey: CacheKeys.cacheSize)
        userDefaults.set(Date(), forKey: CacheKeys.cacheLastCleanup)
    }
    
    // Clear cache for specific group
    func clearCacheForGroup(_ groupId: String) {
        userDefaults.removeObject(forKey: CacheKeys.merchItems(forGroup: groupId))
        userDefaults.removeObject(forKey: CacheKeys.merchSales(forGroup: groupId))
        
        // Update cache size (estimate)
        let currentCacheSize = userDefaults.integer(forKey: CacheKeys.cacheSize)
        userDefaults.set(max(0, currentCacheSize - 200000), forKey: CacheKeys.cacheSize) // Rough estimate
    }
    
    // MARK: - Generic Cache Methods
    
    func cacheData<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            updateCacheSize(adding: encodedData.count)
            userDefaults.set(encodedData, forKey: key)
        } catch {
            // Check if this is a Firestore encoding error
            let errorDescription = error.localizedDescription
            if errorDescription.contains("DocumentID") ||
               errorDescription.contains("Firestore") ||
               errorDescription.contains("encodingIsNotSupported") {
                // Silently skip these errors
                return
            }
            
            logger.error("Error caching data for key \(key): \(error.localizedDescription)")
        }
    }
    
    func loadData<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.error("Error loading cached data for key \(key): \(error.localizedDescription)")
            return nil
        }
    }
}
