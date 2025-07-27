import Foundation
import UIKit

class LegalConsentTracker {
    static let shared = LegalConsentTracker()
    
    private let keychain = Keychain()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func recordUserConsent() {
        let timestamp = Date()
        let deviceInfo = getDeviceInfo()
        let appVersion = getAppVersion()
        let termsVersion = "v2025.1"
        
        let consentRecord = LegalConsentRecord(
            timestamp: timestamp,
            deviceInfo: deviceInfo,
            appVersion: appVersion,
            termsVersion: termsVersion,
            ipAddress: "Not tracked for privacy",
            userAgent: deviceInfo.systemVersion
        )
        
        saveToUserDefaults(consentRecord)
        saveToKeychain(consentRecord)
        saveToDocuments(consentRecord)
        
        let firebaseSync = ConsentFirebaseSync()
        let consentData: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970,
            "device_info": [
                "model": deviceInfo.deviceModel,
                "system_name": deviceInfo.systemName,
                "system_version": deviceInfo.systemVersion,
                "device_id": deviceInfo.deviceId
            ],
            "app_version": appVersion,
            "terms_version": termsVersion,
            "consent_given": true,
            "legal_record_id": UUID().uuidString
        ]
        firebaseSync.uploadConsent(consentData)
    }
    
    func hasUserConsented() -> Bool {
        return userDefaults.bool(forKey: "HasAgreedToTerms") ||
               keychain.hasConsentRecord() ||
               documentsHaveConsentRecord()
    }
    
    func getConsentDate() -> Date? {
        if let date = userDefaults.object(forKey: "TermsAgreementDate") as? Date {
            return date
        }
        
        if let record = loadFromKeychain() {
            return record.timestamp
        }
        
        if let record = loadFromDocuments() {
            return record.timestamp
        }
        
        return nil
    }
    
    func getConsentRecord() -> LegalConsentRecord? {
        if let record = loadFromKeychain() {
            return record
        }
        
        if let record = loadFromDocuments() {
            return record
        }
        
        if let date = userDefaults.object(forKey: "TermsAgreementDate") as? Date {
            return LegalConsentRecord(
                timestamp: date,
                deviceInfo: getDeviceInfo(),
                appVersion: getAppVersion(),
                termsVersion: "v2025.1",
                ipAddress: "Not tracked",
                userAgent: getDeviceInfo().systemVersion
            )
        }
        
        return nil
    }
    
    func resetConsent() {
        userDefaults.removeObject(forKey: "HasAgreedToTerms")
        userDefaults.removeObject(forKey: "TermsAgreementDate")
        keychain.removeConsentRecord()
        removeFromDocuments()
    }
    
    private func saveToUserDefaults(_ record: LegalConsentRecord) {
        userDefaults.set(true, forKey: "HasAgreedToTerms")
        userDefaults.set(record.timestamp, forKey: "TermsAgreementDate")
        userDefaults.set(record.termsVersion, forKey: "TermsVersion")
        userDefaults.set(record.appVersion, forKey: "ConsentAppVersion")
    }
    
    private func saveToKeychain(_ record: LegalConsentRecord) {
        keychain.saveConsentRecord(record)
    }
    
    private func saveToDocuments(_ record: LegalConsentRecord) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let consentFile = documentsPath.appendingPathComponent("legal_consent.json")
        
        do {
            let data = try JSONEncoder().encode(record)
            try data.write(to: consentFile)
        } catch {
        }
    }
    
    private func loadFromKeychain() -> LegalConsentRecord? {
        return keychain.loadConsentRecord()
    }
    
    private func loadFromDocuments() -> LegalConsentRecord? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let consentFile = documentsPath.appendingPathComponent("legal_consent.json")
        
        do {
            let data = try Data(contentsOf: consentFile)
            return try JSONDecoder().decode(LegalConsentRecord.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func documentsHaveConsentRecord() -> Bool {
        return loadFromDocuments() != nil
    }
    
    private func removeFromDocuments() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let consentFile = documentsPath.appendingPathComponent("legal_consent.json")
        try? FileManager.default.removeItem(at: consentFile)
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        
        return DeviceInfo(
            deviceModel: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceId: device.identifierForVendor?.uuidString ?? "Unknown"
        )
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

struct LegalConsentRecord: Codable {
    let timestamp: Date
    let deviceInfo: DeviceInfo
    let appVersion: String
    let termsVersion: String
    let ipAddress: String
    let userAgent: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        formatter.timeZone = TimeZone.current
        return formatter.string(from: timestamp)
    }
}

struct DeviceInfo: Codable {
    let deviceModel: String
    let systemName: String
    let systemVersion: String
    let deviceId: String
}

private class Keychain {
    private let service = "com.bandsync.legal.consent"
    private let account = "user.agreement"
    
    func saveConsentRecord(_ record: LegalConsentRecord) {
        do {
            let data = try JSONEncoder().encode(record)
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary)
            
            let _ = SecItemAdd(query as CFDictionary, nil)
        } catch {
        }
    }
    
    func loadConsentRecord() -> LegalConsentRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(LegalConsentRecord.self, from: data)
        } catch {
            return nil
        }
    }
    
    func hasConsentRecord() -> Bool {
        return loadConsentRecord() != nil
    }
    
    func removeConsentRecord() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
