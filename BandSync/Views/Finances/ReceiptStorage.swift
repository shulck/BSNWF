// ReceiptStorage.swift
// Clean version - ONLY Firebase Storage, no local storage

import Foundation
import UIKit

class ReceiptStorage {
    
    // MARK: - Public Interface (only Firebase Storage)
    
    /// Saves receipt to Firebase Storage (asynchronously)
    static func saveReceipt(image: UIImage, recordId: String, completion: @escaping (String?) -> Void) {
        FirebaseStorageService.shared.uploadReceiptImage(image, recordId: recordId) { firebaseURL in
            completion(firebaseURL)
        }
    }
    
    /// Loads receipt from Firebase Storage (asynchronously)
    static func loadReceipt(url: String, completion: @escaping (UIImage?) -> Void) {
        guard FirebaseStorageService.isFirebaseStorageURL(url) else {
            completion(nil)
            return
        }
        
        // First check cache
        if let cachedImage = loadReceiptFromCache(url: url) {
            completion(cachedImage)
            return
        }
        
        // Load from Firebase Storage
        FirebaseStorageService.shared.downloadReceiptImage(from: url) { image in
            if let image = image {
                // Cache downloaded image
                cacheReceipt(image: image, url: url)
            }
            completion(image)
        }
    }
    
    /// Deletes receipt from Firebase Storage (asynchronously)
    static func deleteReceipt(url: String, completion: @escaping (Bool) -> Void) {
        guard FirebaseStorageService.isFirebaseStorageURL(url) else {
            completion(false)
            return
        }
        
        // Remove from cache
        removeCachedReceipt(url: url)
        
        // Delete from Firebase Storage
        FirebaseStorageService.shared.deleteReceiptImage(url: url, completion: completion)
    }
    
    // MARK: - Synchronous Methods (for backward compatibility)
    
    /// Synchronous save (returns placeholder, real save is asynchronous)
    static func saveReceipt(image: UIImage, recordId: String) -> String? {
        // For backward compatibility - save asynchronously
        saveReceipt(image: image, recordId: recordId) { success in
            // Callback handled asynchronously
        }
        
        // Return placeholder URL (will be replaced with real one)
        return "firebase://uploading/\(recordId)"
    }
    
    /// Synchronous load (only from cache)
    static func loadReceipt(path: String) -> UIImage? {
        // Only from cache for synchronous loading
        return loadReceiptFromCache(url: path)
    }
    
    /// Synchronous delete (starts asynchronous deletion)
    static func deleteReceipt(path: String) {
        deleteReceipt(url: path) { success in
            // Callback handled asynchronously
        }
    }
    
    // MARK: - Memory Caching System
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    /// Caches image in memory
    private static func cacheReceipt(image: UIImage, url: String) {
        let cacheKey = extractCacheKey(from: url)
        imageCache.setObject(image, forKey: cacheKey as NSString)
    }
    
    /// Loads image from memory cache
    private static func loadReceiptFromCache(url: String) -> UIImage? {
        let cacheKey = extractCacheKey(from: url)
        return imageCache.object(forKey: cacheKey as NSString)
    }
    
    /// Removes image from memory cache
    private static func removeCachedReceipt(url: String) {
        let cacheKey = extractCacheKey(from: url)
        imageCache.removeObject(forKey: cacheKey as NSString)
    }
    
    /// Extracts cache key from URL
    private static func extractCacheKey(from url: String) -> String {
        if let fileName = url.components(separatedBy: "/").last?.components(separatedBy: "?").first {
            return fileName
        }
        return url.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
    }
    
    /// Clears all memory cache
    static func clearCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Local Storage Cleanup
    
    /// Deletes ALL local receipts permanently
    static func deleteAllLocalReceipts() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let receiptsFolder = documentsDirectory.appendingPathComponent("receipts")
        
        guard FileManager.default.fileExists(atPath: receiptsFolder.path) else {
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: receiptsFolder.path)
            let receiptFiles = files.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") }
            
            for fileName in receiptFiles {
                let filePath = receiptsFolder.appendingPathComponent(fileName)
                try FileManager.default.removeItem(at: filePath)
            }
            
            // Remove folder itself if empty
            let remainingFiles = try FileManager.default.contentsOfDirectory(atPath: receiptsFolder.path)
            if remainingFiles.isEmpty {
                try FileManager.default.removeItem(at: receiptsFolder)
            }
            
        } catch {
            // Error handling without console output
        }
    }
    
    /// Counts size of local receipt files
    static func getLocalReceiptsSize() -> (fileCount: Int, totalSizeBytes: Int64) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (0, 0)
        }
        
        let receiptsFolder = documentsDirectory.appendingPathComponent("receipts")
        
        guard FileManager.default.fileExists(atPath: receiptsFolder.path) else {
            return (0, 0)
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: receiptsFolder.path)
            let receiptFiles = files.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") || $0.hasSuffix(".png") }
            
            var totalSize: Int64 = 0
            
            for fileName in receiptFiles {
                let filePath = receiptsFolder.appendingPathComponent(fileName)
                let attributes = try FileManager.default.attributesOfItem(atPath: filePath.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            return (receiptFiles.count, totalSize)
            
        } catch {
            return (0, 0)
        }
    }
    
    /// Formats file size to human readable format
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
