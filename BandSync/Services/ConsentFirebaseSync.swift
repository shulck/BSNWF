//
//  ConsentFirebaseSync.swift
//  BandSync
//
//  Created by Auto-Generated on 2025
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ConsentFirebaseSync: ObservableObject {
    
    private let db = Firestore.firestore()
    private let collection = "user_consents"
    
    func uploadConsent(_ consentData: [String: Any]) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        let timestamp = Timestamp()
        
        var dataToUpload = consentData
        dataToUpload["device_id"] = deviceId
        dataToUpload["upload_timestamp"] = timestamp
        dataToUpload["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        dataToUpload["platform"] = "iOS"
        
        let documentId = "\(deviceId)_\(Int(Date().timeIntervalSince1970))"
        
        db.collection(collection).document(documentId).setData(dataToUpload) { error in
            if error != nil {
                self.scheduleRetry(dataToUpload, documentId: documentId)
            } else {
                UserDefaults.standard.set(true, forKey: "consent_uploaded_to_firebase")
            }
        }
    }
    
    private func scheduleRetry(_ data: [String: Any], documentId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.retryUpload(data, documentId: documentId)
        }
    }
    
    private func retryUpload(_ data: [String: Any], documentId: String) {
        db.collection(collection).document(documentId).setData(data) { error in
            if error == nil {
                UserDefaults.standard.set(true, forKey: "consent_uploaded_to_firebase")
            }
        }
    }
    
    func getConsentsForCurrentDevice(completion: @escaping ([QueryDocumentSnapshot]?) -> Void) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        db.collection(collection)
            .whereField("device_id", isEqualTo: deviceId)
            .order(by: "upload_timestamp", descending: true)
            .getDocuments { snapshot, error in
                if error != nil {
                    completion(nil)
                } else {
                    completion(snapshot?.documents)
                }
            }
    }
    
    func exportConsentsAsJSON(completion: @escaping (String?) -> Void) {
        getConsentsForCurrentDevice { documents in
            guard let documents = documents else {
                completion(nil)
                return
            }
            
            let consentsData = documents.map { doc in
                var data = doc.data()
                data["document_id"] = doc.documentID
                return data
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: consentsData, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: .utf8)
                completion(jsonString)
            } catch {
                completion(nil)
            }
        }
    }
    
    var isUploadedToFirebase: Bool {
        return UserDefaults.standard.bool(forKey: "consent_uploaded_to_firebase")
    }
    
    func resetUploadStatus() {
        UserDefaults.standard.removeObject(forKey: "consent_uploaded_to_firebase")
    }
}
