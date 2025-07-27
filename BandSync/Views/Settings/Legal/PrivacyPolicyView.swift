import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Text("Your privacy is important to us. This policy explains how BandSync collects, uses, and protects your information to provide the best possible service.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("Our Commitment".localized)
            }
            
            Section {
                PolicyRow(title: "Account Information".localized, description: "Name, email, and profile details for authentication and personalization".localized)
                PolicyRow(title: "Band Data".localized, description: "Group information, member details, and organizational structure".localized)
                PolicyRow(title: "Events & Scheduling".localized, description: "Calendar data, event details, and attendance information".localized)
                PolicyRow(title: "Communication Data".localized, description: "Messages and coordination information within your band".localized)
                PolicyRow(title: "Financial Information".localized, description: "Expense tracking and transaction records (no payment details stored)".localized)
                PolicyRow(title: "Document Storage".localized, description: "Files and documents shared through Google Drive integration".localized)
                PolicyRow(title: "Usage Analytics".localized, description: "App performance data and feature usage statistics for improvement".localized)
            } header: {
                Text("Information We Collect".localized)
            }
            
            Section {
                PolicyRow(title: "Service Delivery".localized, description: "Provide band management tools and collaboration features".localized)
                PolicyRow(title: "Synchronization".localized, description: "Keep your data updated across all your devices".localized)
                PolicyRow(title: "Notifications".localized, description: "Send relevant updates about events and band activities".localized)
                PolicyRow(title: "Security".localized, description: "Protect your account and prevent unauthorized access".localized)
                PolicyRow(title: "Improvement".localized, description: "Enhance app performance and develop new features".localized)
                PolicyRow(title: "Customer Support".localized, description: "Provide assistance and resolve technical issues".localized)
            } header: {
                Text("How We Use Your Information".localized)
            }
            
            Section {
                PolicyRow(title: "No Data Sales".localized, description: "We never sell your personal information to third parties".localized)
                PolicyRow(title: "Service Providers".localized, description: "Trusted partners like Firebase and Google Drive under strict agreements".localized)
                PolicyRow(title: "Legal Requirements".localized, description: "Only when required by law or to protect user safety".localized)
                PolicyRow(title: "Your Consent".localized, description: "With your explicit permission for specific purposes".localized)
                PolicyRow(title: "Business Transfers".localized, description: "In the event of a merger or acquisition, with user notification".localized)
            } header: {
                Text("Information Sharing".localized)
            }
            
            Section {
                PolicyRow(title: "Data Encryption".localized, description: "All data is encrypted during transmission and storage".localized)
                PolicyRow(title: "Secure Authentication".localized, description: "Strong password requirements and optional biometric security".localized)
                PolicyRow(title: "Access Controls".localized, description: "Role-based permissions and data access limitations".localized)
                PolicyRow(title: "Regular Security Reviews".localized, description: "Ongoing security assessments and updates".localized)
                PolicyRow(title: "Incident Response".localized, description: "Prompt notification and response to any security issues".localized)
            } header: {
                Text("Security Measures".localized)
            }
            
            Section {
                PolicyRow(title: "Access Your Data".localized, description: "View and download your personal information anytime".localized)
                PolicyRow(title: "Correct Information".localized, description: "Update or correct any inaccurate data through the app".localized)
                PolicyRow(title: "Delete Your Data".localized, description: "Remove your account and associated data permanently".localized)
                PolicyRow(title: "Data Portability".localized, description: "Export your data in standard, portable formats".localized)
                PolicyRow(title: "Control Communications".localized, description: "Manage notification preferences and marketing communications".localized)
                PolicyRow(title: "Withdraw Consent".localized, description: "Revoke previously given permissions at any time".localized)
            } header: {
                Text("Your Privacy Rights".localized)
            }
            
            Section {
                PolicyRow(title: "No Payment Storage".localized, description: "We do not store credit card or banking information".localized)
                PolicyRow(title: "App Store Processing".localized, description: "All payments are securely processed by Apple".localized)
                PolicyRow(title: "Purchase Verification".localized, description: "We may verify purchases through Apple's secure servers".localized)
                PolicyRow(title: "Subscription Management".localized, description: "Billing history is maintained by Apple, not BandSync".localized)
            } header: {
                Text("Payment Information".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Age Requirements".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("BandSync is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Parental Responsibility".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("If you believe a child under 13 has provided us with personal information, please contact us immediately so we can delete it.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Children's Privacy".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Policy Updates".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We may update this privacy policy periodically to reflect changes in our practices or legal requirements. We will notify users of significant changes through the app.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Continued Use".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("Your continued use of BandSync after policy updates constitutes acceptance of the revised terms.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Policy Changes".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Best Efforts Commitment".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We are committed to protecting your privacy and implement industry-standard security measures. However, no system is completely secure, and we cannot guarantee absolute security.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Data Backup Recommendation".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We recommend maintaining your own backups of important data. While we strive to protect and preserve your information, technical issues can occasionally occur.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Third-Party Services".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("While we carefully select trusted partners, we cannot control the privacy practices of third-party services. Please review their privacy policies as well.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Important Notices".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last updated: January 2025".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("For privacy-related questions, please contact our support team through the app.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("We are committed to transparency and protecting your personal information.".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Privacy Policy".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PolicyRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}
