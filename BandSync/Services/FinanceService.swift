// FinanceService.swift

import Foundation
import FirebaseFirestore

final class FinanceService: ObservableObject {
    static let shared = FinanceService()

    @Published var records: [FinanceRecord] = []
    private let db = Firestore.firestore()
    
    private let offlineRecordsKey = "offlineFinanceRecords"
    
    private init() {
        // Load cached records on initialization
        let cachedRecords = fetchCachedRecords()
        if !cachedRecords.isEmpty {
            print("FinanceService: Loaded \(cachedRecords.count) cached records on init")
            self.records = cachedRecords
        }
    }

    func fetch(for groupId: String) {
        print("FinanceService: Fetching records for groupId: \(groupId)")
        
        // Load cached records first as fallback
        let allCachedRecords = fetchCachedRecords()
        let cachedRecords = allCachedRecords.filter { $0.groupId == groupId }
        if !cachedRecords.isEmpty {
            print("FinanceService: Found \(cachedRecords.count) cached records for groupId \(groupId), setting them temporarily")
            DispatchQueue.main.async {
                self.records = cachedRecords
            }
        }
        
        db.collection("finances")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("FinanceService: Error fetching records: \(error.localizedDescription)")
                    // Keep cached records if network fetch fails
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("FinanceService: No documents found")
                    DispatchQueue.main.async {
                        // Only clear records if we're sure there's no data, not if cached records exist
                        if cachedRecords.isEmpty {
                            self?.records = []
                        }
                    }
                    return
                }
                
                print("FinanceService: Found \(docs.count) documents")
                var loadedRecords: [FinanceRecord] = []
                
                for document in docs {
                    let data = document.data()
                    let id = document.documentID
                    
                    guard let typeString = data["type"] as? String,
                          let type = FinanceType(rawValue: typeString),
                          let amount = data["amount"] as? Double,
                          let currency = data["currency"] as? String,
                          let category = data["category"] as? String,
                          let groupId = data["groupId"] as? String else {
                        print("FinanceService: Skipping invalid document: \(id)")
                        continue
                    }
                    
                    let date: Date
                    if let timestamp = data["date"] as? Timestamp {
                        date = timestamp.dateValue()
                    } else {
                        date = Date()
                    }
                    
                    let details = data["details"] as? String ?? ""
                    let receiptUrl = data["receiptUrl"] as? String
                    
                    let record = FinanceRecord(
                        id: id,
                        type: type,
                        amount: amount,
                        currency: currency,
                        category: category,
                        details: details,
                        date: date,
                        receiptUrl: receiptUrl,
                        groupId: groupId
                    )
                    
                    loadedRecords.append(record)
                }
                
                DispatchQueue.main.async {
                    print("FinanceService: Setting \(loadedRecords.count) records")
                    // Sort records by date in descending order (newest first) on client side
                    self?.records = loadedRecords.sorted { $0.date > $1.date }
                }
            }
    }

    func add(_ record: FinanceRecord, completion: @escaping (Bool) -> Void) {
        var newRecord = record
        if newRecord.id.isEmpty {
            newRecord.id = UUID().uuidString
        }
        
        let recordData: [String: Any] = [
            "id": newRecord.id,
            "type": newRecord.type.rawValue,
            "amount": newRecord.amount,
            "currency": newRecord.currency,
            "category": newRecord.category,
            "details": newRecord.details,
            "date": Timestamp(date: newRecord.date),
            "groupId": newRecord.groupId
        ]
        
        var finalData = recordData
        if let receiptUrl = newRecord.receiptUrl {
            finalData["receiptUrl"] = receiptUrl
        }
        
        db.collection("finances").document(newRecord.id).setData(finalData) { [weak self] error in
            if let error = error {
                print("FinanceService: Error saving record, caching offline: \(error.localizedDescription)")
                self?.cacheRecord(newRecord)
                completion(false)
            } else {
                print("FinanceService: Record saved successfully, caching and refreshing")
                // Cache the successfully saved record too
                self?.cacheRecord(newRecord)
                self?.fetch(for: newRecord.groupId)
                completion(true)
            }
        }
    }
    
    func update(_ record: FinanceRecord, completion: @escaping (Bool) -> Void) {
        guard !record.id.isEmpty else {
            completion(false)
            return
        }
        
        let recordData: [String: Any] = [
            "id": record.id,
            "type": record.type.rawValue,
            "amount": record.amount,
            "currency": record.currency,
            "category": record.category,
            "details": record.details,
            "date": Timestamp(date: record.date),
            "groupId": record.groupId
        ]
        
        var finalData = recordData
        if let receiptUrl = record.receiptUrl {
            finalData["receiptUrl"] = receiptUrl
        }
        
        db.collection("finances").document(record.id).setData(finalData) { [weak self] error in
            if error != nil {
                completion(false)
            } else {
                self?.fetch(for: record.groupId)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }

    func delete(_ record: FinanceRecord, completion: @escaping (Bool) -> Void = { _ in }) {
        guard !record.id.isEmpty else {
            completion(false)
            return
        }
        
        // Step 1: Delete receipt image from Firebase Storage if exists
        if let receiptUrl = record.receiptUrl,
           !receiptUrl.isEmpty,
           FirebaseStorageService.isFirebaseStorageURL(receiptUrl) {
            print("🗑️ Deleting receipt from Firebase Storage: \(receiptUrl)")
            ReceiptStorage.deleteReceipt(url: receiptUrl) { success in
                if success {
                    print("✅ Receipt deleted from Firebase Storage")
                } else {
                    print("❌ Failed to delete receipt from Firebase Storage")
                }
                // Continue with database deletion regardless of storage result
                self.deleteFromDatabase(record, completion: completion)
            }
        } else {
            // No receipt to delete, proceed with database deletion
            deleteFromDatabase(record, completion: completion)
        }
    }
    
    // Helper function to delete record from database
    private func deleteFromDatabase(_ record: FinanceRecord, completion: @escaping (Bool) -> Void) {
        db.collection("finances").document(record.id).delete { [weak self] error in
            if let error = error {
                print("❌ Failed to delete finance record: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Finance record deleted successfully")
                DispatchQueue.main.async {
                    self?.records.removeAll { $0.id == record.id }
                    completion(true)
                }
            }
        }
    }
    
    func cacheRecord(_ record: FinanceRecord) {
        var records = fetchCachedRecords()
        records.append(record)
        saveCachedRecords(records)
    }
    
    func fetchCachedRecords() -> [FinanceRecord] {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.data(forKey: offlineRecordsKey),
              let records = try? JSONDecoder().decode([FinanceRecord].self, from: data) else {
            return []
        }
        return records
    }
    
    private func saveCachedRecords(_ records: [FinanceRecord]) {
        let userDefaults = UserDefaults.standard
        guard let data = try? JSONEncoder().encode(records) else { return }
        userDefaults.set(data, forKey: offlineRecordsKey)
    }
    
    func removeCachedRecord(_ record: FinanceRecord) {
        var records = fetchCachedRecords()
        records.removeAll { $0.id == record.id }
        saveCachedRecords(records)
    }
    
    func syncCachedRecords(completion: @escaping (Int) -> Void) {
        let records = fetchCachedRecords()
        let group = DispatchGroup()
        var synced = 0
        
        for record in records {
            group.enter()
            add(record) { success in
                if success {
                    self.removeCachedRecord(record)
                    synced += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(synced)
        }
    }
    
    func isCached(_ record: FinanceRecord) -> Bool {
        return fetchCachedRecords().contains { $0.id == record.id }
    }

    var totalIncome: Double {
        records.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Double {
        records.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var profit: Double {
        totalIncome - totalExpense
    }
}
