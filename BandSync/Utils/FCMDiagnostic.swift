import SwiftUI
import FirebaseMessaging
import FirebaseAuth
import UserNotifications

struct FCMDiagnosticView: View {
    @State private var fcmToken: String = "Loading..."
    @State private var apnsToken: String = "Loading..."
    @State private var authState: String = "Loading..."
    @State private var pushPermission: String = "Loading..."
    @State private var apsEnvironment: String = "Loading..."
    @State private var bundleId: String = "Loading..."
    
    var body: some View {
        NavigationView {
            List {
                Section("App Information") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bundle ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bundleId)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("APS Environment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(apsEnvironment)
                            .font(.caption)
                            .fontWeight(apsEnvironment.contains("production") ? .bold : .regular)
                            .foregroundColor(apsEnvironment.contains("production") ? .green : .orange)
                            .textSelection(.enabled)
                    }
                }
                
                Section("FCM Token") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fcmToken)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
                
                Section("APNs Token") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(apnsToken)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
                
                Section("Auth State") {
                    Text(authState)
                        .font(.caption)
                }
                
                Section("Push Permission") {
                    Text(pushPermission)
                        .font(.caption)
                }
                
                Section("Actions") {
                    Button("Refresh Tokens") {
                        loadDiagnosticData()
                    }
                    
                    Button("Request Push Permission") {
                        requestPushPermission()
                    }
                    
                    Button("Copy All Info") {
                        copyDiagnosticInfo()
                    }
                }
            }
            .navigationTitle("Push Diagnostic")
            .onAppear {
                loadDiagnosticData()
            }
        }
    }
    
    private func loadDiagnosticData() {
        // Bundle ID
        bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        print("📦 Bundle ID: \(bundleId)")
        
        // APS Environment from entitlements
        if Bundle.main.path(forResource: "BandSync", ofType: "entitlements") != nil {
            apsEnvironment = "Development (BandSync.entitlements)"
        } else if Bundle.main.path(forResource: "BandSyncRelease", ofType: "entitlements") != nil {
            apsEnvironment = "Production (BandSyncRelease.entitlements)"
        } else {
            // Try to read from compiled entitlements
            if let entitlements = Bundle.main.infoDictionary?["com.apple.developer.aps-environment"] as? String {
                apsEnvironment = entitlements.capitalized
            } else {
                apsEnvironment = "Unknown - Check entitlements"
            }
        }
        print("🔐 APS Environment: \(apsEnvironment)")
        
        // FCM Token
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let token = token {
                    self.fcmToken = token
                    print("🔥 Current FCM Token: \(token)")
                } else if let error = error {
                    self.fcmToken = "Error: \(error.localizedDescription)"
                    print("❌ FCM Token Error: \(error)")
                }
            }
        }
        
        // APNs Token
        if let apnsTokenData = Messaging.messaging().apnsToken {
            apnsToken = apnsTokenData.map { String(format: "%02.2hhx", $0) }.joined()
            print("📱 Current APNs Token: \(apnsToken)")
        } else {
            apnsToken = "Not available"
            print("⚠️ APNs Token not available")
        }
        
        // Auth State
        if let user = Auth.auth().currentUser {
            authState = "Logged in as: \(user.uid)"
            print("👤 User authenticated: \(user.uid)")
        } else {
            authState = "Not logged in"
            print("❌ User not authenticated")
        }
        
        // Push Permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self.pushPermission = "✅ Authorized"
                case .denied:
                    self.pushPermission = "❌ Denied"
                case .notDetermined:
                    self.pushPermission = "⚠️ Not Determined"
                case .provisional:
                    self.pushPermission = "🔔 Provisional"
                case .ephemeral:
                    self.pushPermission = "⏰ Ephemeral"
                @unknown default:
                    self.pushPermission = "❓ Unknown"
                }
                print("🔔 Push Permission: \(self.pushPermission)")
            }
        }
    }
    
    private func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("✅ Push permission granted, registering for remote notifications")
                } else {
                    print("❌ Push permission denied")
                }
                loadDiagnosticData()
            }
        }
    }
    
    private func copyDiagnosticInfo() {
        let info = """
        BandSync Push Diagnostic Info:
        Bundle ID: \(bundleId)
        APS Environment: \(apsEnvironment)
        FCM Token: \(fcmToken)
        APNs Token: \(apnsToken)
        Auth State: \(authState)
        Push Permission: \(pushPermission)
        """
        UIPasteboard.general.string = info
        print("📋 Diagnostic info copied to clipboard")
    }
}

import UserNotifications
