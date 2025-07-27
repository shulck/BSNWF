import SwiftUI

struct ConsentDetailsView: View {
    @State private var consentRecord: LegalConsentRecord?
    
    var body: some View {
        List {
            if let record = consentRecord {
                Section {
                    DetailRow(title: "Agreement Date".localized, value: record.formattedTimestamp)
                    DetailRow(title: "Terms Version".localized, value: record.termsVersion)
                    DetailRow(title: "App Version".localized, value: record.appVersion)
                } header: {
                    Text("Consent Information".localized)
                }
                
                Section {
                    DetailRow(title: "Device Model".localized, value: record.deviceInfo.deviceModel)
                    DetailRow(title: "Operating System".localized, value: "\(record.deviceInfo.systemName) \(record.deviceInfo.systemVersion)")
                    DetailRow(title: "Device Identifier".localized, value: record.deviceInfo.deviceId)
                } header: {
                    Text("Device Information".localized)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Agreement Record".localized)
                            .font(.body)
                            .fontWeight(.bold)
                        
                        Text("This record confirms that you voluntarily agreed to our Terms of Service and Privacy Policy on the date shown above.".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("What This Means".localized)
                            .font(.body)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• You have read and accepted our terms and privacy policy".localized)
                            Text("• Your consent was given freely and voluntarily".localized)
                            Text("• You understand how we collect and use your data".localized)
                            Text("• You can withdraw consent at any time".localized)
                            Text("• This record helps us maintain compliance with privacy laws".localized)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Text("Your Rights".localized)
                            .font(.body)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Access and review your personal data".localized)
                            Text("• Request corrections to inaccurate information".localized)
                            Text("• Delete your account and data".localized)
                            Text("• Export your data in portable formats".localized)
                            Text("• Contact support with questions or concerns".localized)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Agreement Details".localized)
                }
                
                Section {
                    Button("Export Consent Record".localized) {
                        exportConsentRecord(record)
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset Consent (Testing Only)".localized) {
                        resetConsent()
                    }
                    .foregroundColor(.orange)
                } header: {
                    Text("Actions".localized)
                } footer: {
                    Text("Resetting consent is intended for testing purposes and will require you to review and accept our terms again when you next open the app.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text("No Consent Record Found".localized)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("You have not yet reviewed and accepted our Terms of Service and Privacy Policy. You will be prompted to review these documents when you next launch the app.".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Your privacy and understanding of our terms are important to us.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 20)
                } header: {
                    Text("Consent Status".localized)
                }
            }
        }
        .navigationTitle("Consent Details".localized)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadConsentRecord()
        }
    }
    
    private func loadConsentRecord() {
        consentRecord = LegalConsentTracker.shared.getConsentRecord()
    }
    
    private func exportConsentRecord(_ record: LegalConsentRecord) {
        // Create a user-friendly version of the consent record
        let exportText = """
        \("BANDSYNC CONSENT RECORD".localized)
        ======================
        
        \("Agreement Date".localized): \(record.formattedTimestamp)
        \("Terms Version".localized): \(record.termsVersion)
        \("App Version".localized): \(record.appVersion)
        
        \("Device Information".localized):
        - \("Model".localized): \(record.deviceInfo.deviceModel)
        - \("System".localized): \(record.deviceInfo.systemName) \(record.deviceInfo.systemVersion)
        - \("Device ID".localized): \(record.deviceInfo.deviceId)
        
        \("Summary".localized):
        \("You voluntarily agreed to BandSync's Terms of Service and Privacy Policy on the date shown above. This record is maintained for compliance with privacy regulations and to document your informed consent.".localized)
        
        \("Your Rights".localized):
        - \("Access your personal data".localized)
        - \("Request data corrections".localized)
        - \("Delete your account and data".localized)
        - \("Export your data".localized)
        - \("Contact support for assistance".localized)
        
        \("Record Generated".localized): \(Date().formatted(date: .abbreviated, time: .shortened))
        """
        
        let activityController = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func resetConsent() {
        LegalConsentTracker.shared.resetConsent()
        consentRecord = nil
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.localized)
                .font(.body)
                .fontWeight(.medium)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        ConsentDetailsView()
    }
}
