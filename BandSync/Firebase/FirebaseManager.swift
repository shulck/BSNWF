//
//  FirebaseManager.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
#if DEBUG
import FirebaseAppCheck
#endif

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private(set) var isInitialized = false
    private let initializationLock = NSLock()
    
    private init() {}
    
    func initialize() {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        guard !isInitialized else {
            return
        }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        isInitialized = true
        configureFirebaseSettings()
    }
    
    func markAsInitialized() {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        isInitialized = true
        configureFirebaseSettings()
    }
    
    private func configureFirebaseSettings() {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        if #available(iOS 13.0, *) {
            settings.cacheSettings = PersistentCacheSettings()
        } else {
            settings.isPersistenceEnabled = true
        }
        
        db.settings = settings
        
        Task {
            await checkFirestoreConnection()
        }
    }
    
    private func checkFirestoreConnection() async {
        do {
            let db = Firestore.firestore()
            _ = try await db.collection("_healthcheck").limit(to: 1).getDocuments()
        } catch {
        }
    }
    
    func ensureInitialized() {
        guard !isInitialized else { return }
        initialize()
    }
    
    func updateUserOnlineStatus(isOnline: Bool) {
        guard let userId = UserDefaults.standard.string(forKey: "userID") else {
            return
        }

        let userRef = Firestore.firestore().collection("users").document(userId)
        let data: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": FieldValue.serverTimestamp()
        ]

        userRef.updateData(data) { error in
        }
    }
    
    func checkFirebaseConnection(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("_health").limit(to: 1).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    func getFirebaseInfo() -> [String: Any] {
        guard let app = FirebaseApp.app() else {
            return ["error": "Firebase not initialized"]
        }
        
        let options = app.options
        
        return [
            "name": app.name,
            "projectID": options.projectID as Any,
            "bundleID": options.bundleID as Any,
            "apiKey": options.apiKey as Any,
            "isInitialized": isInitialized,
            "fcmAPI": "V1"
        ]
    }
    
    func clearFirebaseCache(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.clearPersistence { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    func setFirebaseNetworkEnabled(_ enabled: Bool) {
        let db = Firestore.firestore()
        
        if enabled {
            db.enableNetwork { error in
            }
        } else {
            db.disableNetwork { error in
            }
        }
    }
    
    func saveFCMToken(_ token: String) async throws {
        guard let userId = UserDefaults.standard.string(forKey: "userID") else {
            throw NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user ID found"])
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        do {
            try await userRef.updateData([
                "fcmToken": token,
                "fcmTokenUpdated": FieldValue.serverTimestamp(),
                "environment": "development",
                "fcmAPI": "V1",
                "apnsConfigured": true
            ])
        } catch {
            throw error
        }
    }
    
    func getFirebaseStats() -> [String: Any] {
        return [
            "isInitialized": isInitialized,
            "timestamp": Date().timeIntervalSince1970,
            "environment": "development",
            "fcmAPI": "V1",
            "fcmConfigured": true,
            "apnsConfigured": true,
            "legacyAPIUsed": false
        ]
    }
    
    func reloadFirebaseSettings() {
        guard isInitialized else {
            return
        }
        
        configureFirebaseSettings()
    }
    
    func checkFCMStatus() -> [String: Any] {
        return [
            "apiVersion": "V1",
            "isConfigured": true,
            "usesAPNs": true,
            "legacySupport": false,
            "status": "ready"
        ]
    }
    
    func testFCMConfiguration() {
    }
}
