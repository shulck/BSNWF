import SwiftUI

struct ConsentDetailsView: View {
    @State private var consentRecord: LegalConsentRecord?
    
    var body: some View {
        List {
            if let record = consentRecord {
                Section {
                    DetailRow(title: NSLocalizedString("Agreement Date", comment: "Label for agreement date"), value: record.formattedTimestamp)
                    DetailRow(title: NSLocalizedString("Terms Version", comment: "Label for terms version"), value: record.termsVersion)
                    DetailRow(title: NSLocalizedString("App Version", comment: "Label for app version"), value: record.appVersion)
                } header: {
                    Text(NSLocalizedString("Consent Information", comment: "Section header for consent information"))
                }
                
                Section {
                    DetailRow(title: NSLocalizedString("Device Model", comment: "Label for device model"), value: record.deviceInfo.deviceModel)
                    DetailRow(title: NSLocalizedString("Operating System", comment: "Label for operating system"), value: "\(record.deviceInfo.systemName) \(record.deviceInfo.systemVersion)")
                    DetailRow(title: NSLocalizedString("Device Identifier", comment: "Label for device identifier"), value: record.deviceInfo.deviceId)
                } header: {
                    Text(NSLocalizedString("Device Information", comment: "Section header for device information"))
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("Agreement Record", comment: "Title for agreement record section"))
                            .font(.body)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("This record confirms that you voluntarily agreed to our Terms of Service and Privacy Policy on the date shown above.", comment: "Explanation of agreement record"))
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("What This Means", comment: "Section title for what agreement means"))
                            .font(.body)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("• You have read and accepted our terms and privacy policy", comment: "Agreement point 1"))
                            Text(NSLocalizedString("• Your consent was given freely and voluntarily", comment: "Agreement point 2"))
                            Text(NSLocalizedString("• You understand how we collect and use your data", comment: "Agreement point 3"))
                            Text(NSLocalizedString("• You can withdraw consent at any time", comment: "Agreement point 4"))
                            Text(NSLocalizedString("• This record helps us maintain compliance with privacy laws", comment: "Agreement point 5"))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("Your Rights", comment: "Section title for user rights"))
                            .font(.body)
                            .fontWeight(.bold)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("• Access and review your personal data", comment: "User right 1"))
                            Text(NSLocalizedString("• Request corrections to inaccurate information", comment: "User right 2"))
                            Text(NSLocalizedString("• Delete your account and data", comment: "User right 3"))
                            Text(NSLocalizedString("• Export your data in portable formats", comment: "User right 4"))
                            Text(NSLocalizedString("• Contact support with questions or concerns", comment: "User right 5"))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString("Agreement Details", comment: "Section header for agreement details"))
                }
                
                Section {
                    Button(NSLocalizedString("Export Consent Record", comment: "Button to export consent record")) {
                        exportConsentRecord(record)
                    }
                    .foregroundColor(.blue)
                    
                    Button(NSLocalizedString("Reset Consent (Testing Only)", comment: "Button to reset consent for testing")) {
                        resetConsent()
                    }
                    .foregroundColor(.orange)
                } header: {
                    Text(NSLocalizedString("Actions", comment: "Section header for action buttons"))
                } footer: {
                    Text(NSLocalizedString("Resetting consent is intended for testing purposes and will require you to review and accept our terms again when you next open the app.", comment: "Footer text explaining reset consent"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text(NSLocalizedString("No Consent Record Found", comment: "Title when no consent record exists"))
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(NSLocalizedString("You have not yet reviewed and accepted our Terms of Service and Privacy Policy. You will be prompted to review these documents when you next launch the app.", comment: "Explanation when no consent record exists"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(NSLocalizedString("Your privacy and understanding of our terms are important to us.", comment: "Additional note about privacy importance"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 20)
                } header: {
                    Text(NSLocalizedString("Consent Status", comment: "Section header for consent status"))
                }
            }
        }
        .navigationTitle(NSLocalizedString("Consent Details", comment: "Navigation title for consent details view"))
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
        \(NSLocalizedString("BANDSYNC CONSENT RECORD", comment: "Title for exported consent record"))
        ======================
        
        \(NSLocalizedString("Agreement Date", comment: "Label for agreement date")): \(record.formattedTimestamp)
        \(NSLocalizedString("Terms Version", comment: "Label for terms version")): \(record.termsVersion)
        \(NSLocalizedString("App Version", comment: "Label for app version")): \(record.appVersion)
        
        \(NSLocalizedString("Device Information", comment: "Section header for device information")):
        - \(NSLocalizedString("Model", comment: "Label for device model")): \(record.deviceInfo.deviceModel)
        - \(NSLocalizedString("System", comment: "Label for operating system")): \(record.deviceInfo.systemName) \(record.deviceInfo.systemVersion)
        - \(NSLocalizedString("Device ID", comment: "Label for device identifier")): \(record.deviceInfo.deviceId)
        
        \(NSLocalizedString("Summary", comment: "Summary section title")):
        \(NSLocalizedString("You voluntarily agreed to BandSync's Terms of Service and Privacy Policy on the date shown above. This record is maintained for compliance with privacy regulations and to document your informed consent.", comment: "Summary text for consent record"))
        
        \(NSLocalizedString("Your Rights", comment: "Section title for user rights")):
        - \(NSLocalizedString("Access your personal data", comment: "User right 1 short"))
        - \(NSLocalizedString("Request data corrections", comment: "User right 2 short"))
        - \(NSLocalizedString("Delete your account and data", comment: "User right 3 short"))
        - \(NSLocalizedString("Export your data", comment: "User right 4 short"))
        - \(NSLocalizedString("Contact support for assistance", comment: "User right 5 short"))
        
        \(NSLocalizedString("Record Generated", comment: "Label for record generation date")): \(Date().formatted(date: .abbreviated, time: .shortened))
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
            Text(title)
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
