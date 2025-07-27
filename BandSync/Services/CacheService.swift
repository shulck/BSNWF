//
//  CacheService.swift
//  BandSync

import Foundation
import FirebaseFirestore

final class CacheService {
    static let shared = CacheService()
    
    private let cacheDirectory: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    private init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BandSyncCache")
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
            }
        }
    }
    
    func cacheData<T: Encodable>(_ data: T, forKey key: String) {
        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: cacheDirectory.appendingPathComponent(key))
        } catch {
            if error is FirestoreEncodingError {
                return
            }
            
            let errorDescription = error.localizedDescription
            if errorDescription.contains("DocumentID") ||
               errorDescription.contains("Firestore") ||
               errorDescription.contains("encodingIsNotSupported") {
                return
            }
        }
    }
    
    func loadData<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    func hasCache(forKey key: String) -> Bool {
        return FileManager.default.fileExists(atPath: cacheDirectory.appendingPathComponent(key).path)
    }
    
    func removeCache(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
            }
        }
    }
    
    func clearAllCache() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            
            for url in contents {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
        }
    }
    
    func cacheEvents(_ events: [Event], forGroupId groupId: String) {
        cacheData(events, forKey: "events_\(groupId)")
    }
    
    func getCachedEvents(forGroupId groupId: String) -> [Event]? {
        let events = loadData(forKey: "events_\(groupId)", as: [Event].self)
        return events
    }
    
    func cacheSetlists(_ setlists: [Setlist], forGroupId groupId: String) {
        cacheData(setlists, forKey: "setlists_\(groupId)")
    }
    
    func getCachedSetlists(forGroupId groupId: String) -> [Setlist]? {
        return loadData(forKey: "setlists_\(groupId)", as: [Setlist].self)
    }
    
    func cacheContacts(_ contacts: [Contact], forGroupId groupId: String) {
        cacheData(contacts, forKey: "contacts_\(groupId)")
    }
    
    func getCachedContacts(forGroupId groupId: String) -> [Contact]? {
        return loadData(forKey: "contacts_\(groupId)", as: [Contact].self)
    }
    
    func cacheFinances(_ records: [FinanceRecord], forGroupId groupId: String) {
        cacheData(records, forKey: "finances_\(groupId)")
    }
    
    func getCachedFinances(forGroupId groupId: String) -> [FinanceRecord]? {
        return loadData(forKey: "finances_\(groupId)", as: [FinanceRecord].self)
    }
    
    func cacheMerch(_ items: [MerchItem], forGroupId groupId: String) {
        cacheData(items, forKey: "merch_\(groupId)")
    }
    
    func getCachedMerch(forGroupId groupId: String) -> [MerchItem]? {
        return loadData(forKey: "merch_\(groupId)", as: [MerchItem].self)
    }
    
    func cacheUsers(_ users: [UserModel], forGroupId groupId: String) {
        cacheData(users, forKey: "users_\(groupId)")
    }
    
    func getCachedUsers(forGroupId groupId: String) -> [UserModel]? {
        return loadData(forKey: "users_\(groupId)", as: [UserModel].self)
    }
    
    func getCacheInfo() -> [String: Any] {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
            )
            
            var totalSize: UInt64 = 0
            var fileCount = 0
            var oldestDate: Date = Date()
            
            for url in contents {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? UInt64,
                   let creationDate = attributes[.creationDate] as? Date {
                    totalSize += size
                    fileCount += 1
                    
                    if creationDate < oldestDate {
                        oldestDate = creationDate
                    }
                }
            }
            
            return [
                "totalSize": totalSize,
                "fileCount": fileCount,
                "oldestCache": oldestDate
            ]
        } catch {
            return [
                "totalSize": 0,
                "fileCount": 0,
                "oldestCache": Date()
            ]
        }
    }
    
    func clearOldCache() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            
            for url in contents {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
        }
    }
}
