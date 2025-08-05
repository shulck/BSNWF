import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("Your privacy is important to us. This policy explains how BandSync collects, uses, and protects your information to provide the best possible service.", comment: "Privacy policy - our commitment description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Our Commitment", comment: "Privacy policy - our commitment section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("Account Information", comment: "Privacy policy - account information data type"), description: NSLocalizedString("Name, email, and profile details for authentication and personalization", comment: "Privacy policy - account information description"))
                PolicyRow(title: NSLocalizedString("Band Data", comment: "Privacy policy - band data type"), description: NSLocalizedString("Group information, member details, and organizational structure", comment: "Privacy policy - band data description"))
                PolicyRow(title: NSLocalizedString("Events & Scheduling", comment: "Privacy policy - events and scheduling data type"), description: NSLocalizedString("Calendar data, event details, and attendance information", comment: "Privacy policy - events and scheduling description"))
                PolicyRow(title: NSLocalizedString("Communication Data", comment: "Privacy policy - communication data type"), description: NSLocalizedString("Messages and coordination information within your band", comment: "Privacy policy - communication data description"))
                PolicyRow(title: NSLocalizedString("Financial Information", comment: "Privacy policy - financial information data type"), description: NSLocalizedString("Expense tracking and transaction records (no payment details stored)", comment: "Privacy policy - financial information description"))
                PolicyRow(title: NSLocalizedString("Document Storage", comment: "Privacy policy - document storage data type"), description: NSLocalizedString("Files and documents shared through Google Drive integration", comment: "Privacy policy - document storage description"))
                PolicyRow(title: NSLocalizedString("Usage Analytics", comment: "Privacy policy - usage analytics data type"), description: NSLocalizedString("App performance data and feature usage statistics for improvement", comment: "Privacy policy - usage analytics description"))
            } header: {
                Text(NSLocalizedString("Information We Collect", comment: "Privacy policy - information we collect section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("Service Delivery", comment: "Privacy policy - service delivery usage purpose"), description: NSLocalizedString("Provide band management tools and collaboration features", comment: "Privacy policy - service delivery description"))
                PolicyRow(title: NSLocalizedString("Synchronization", comment: "Privacy policy - synchronization usage purpose"), description: NSLocalizedString("Keep your data updated across all your devices", comment: "Privacy policy - synchronization description"))
                PolicyRow(title: NSLocalizedString("Notifications", comment: "Privacy policy - notifications usage purpose"), description: NSLocalizedString("Send relevant updates about events and band activities", comment: "Privacy policy - notifications description"))
                PolicyRow(title: NSLocalizedString("Security", comment: "Privacy policy - security usage purpose"), description: NSLocalizedString("Protect your account and prevent unauthorized access", comment: "Privacy policy - security description"))
                PolicyRow(title: NSLocalizedString("Improvement", comment: "Privacy policy - improvement usage purpose"), description: NSLocalizedString("Enhance app performance and develop new features", comment: "Privacy policy - improvement description"))
                PolicyRow(title: NSLocalizedString("Customer Support", comment: "Privacy policy - customer support usage purpose"), description: NSLocalizedString("Provide assistance and resolve technical issues", comment: "Privacy policy - customer support description"))
            } header: {
                Text(NSLocalizedString("How We Use Your Information", comment: "Privacy policy - how we use information section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("No Data Sales", comment: "Privacy policy - no data sales sharing policy"), description: NSLocalizedString("We never sell your personal information to third parties", comment: "Privacy policy - no data sales description"))
                PolicyRow(title: NSLocalizedString("Service Providers", comment: "Privacy policy - service providers sharing policy"), description: NSLocalizedString("Trusted partners like Firebase and Google Drive under strict agreements", comment: "Privacy policy - service providers description"))
                PolicyRow(title: NSLocalizedString("Legal Requirements", comment: "Privacy policy - legal requirements sharing policy"), description: NSLocalizedString("Only when required by law or to protect user safety", comment: "Privacy policy - legal requirements description"))
                PolicyRow(title: NSLocalizedString("Your Consent", comment: "Privacy policy - user consent sharing policy"), description: NSLocalizedString("With your explicit permission for specific purposes", comment: "Privacy policy - user consent description"))
                PolicyRow(title: NSLocalizedString("Business Transfers", comment: "Privacy policy - business transfers sharing policy"), description: NSLocalizedString("In the event of a merger or acquisition, with user notification", comment: "Privacy policy - business transfers description"))
            } header: {
                Text(NSLocalizedString("Information Sharing", comment: "Privacy policy - information sharing section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("Data Encryption", comment: "Privacy policy - data encryption security measure"), description: NSLocalizedString("All data is encrypted during transmission and storage", comment: "Privacy policy - data encryption description"))
                PolicyRow(title: NSLocalizedString("Secure Authentication", comment: "Privacy policy - secure authentication security measure"), description: NSLocalizedString("Strong password requirements and optional biometric security", comment: "Privacy policy - secure authentication description"))
                PolicyRow(title: NSLocalizedString("Access Controls", comment: "Privacy policy - access controls security measure"), description: NSLocalizedString("Role-based permissions and data access limitations", comment: "Privacy policy - access controls description"))
                PolicyRow(title: NSLocalizedString("Regular Security Reviews", comment: "Privacy policy - regular security reviews measure"), description: NSLocalizedString("Ongoing security assessments and updates", comment: "Privacy policy - regular security reviews description"))
                PolicyRow(title: NSLocalizedString("Incident Response", comment: "Privacy policy - incident response security measure"), description: NSLocalizedString("Prompt notification and response to any security issues", comment: "Privacy policy - incident response description"))
            } header: {
                Text(NSLocalizedString("Security Measures", comment: "Privacy policy - security measures section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("Access Your Data", comment: "Privacy policy - access your data privacy right"), description: NSLocalizedString("View and download your personal information anytime", comment: "Privacy policy - access your data description"))
                PolicyRow(title: NSLocalizedString("Correct Information", comment: "Privacy policy - correct information privacy right"), description: NSLocalizedString("Update or correct any inaccurate data through the app", comment: "Privacy policy - correct information description"))
                PolicyRow(title: NSLocalizedString("Delete Your Data", comment: "Privacy policy - delete your data privacy right"), description: NSLocalizedString("Remove your account and associated data permanently", comment: "Privacy policy - delete your data description"))
                PolicyRow(title: NSLocalizedString("Data Portability", comment: "Privacy policy - data portability privacy right"), description: NSLocalizedString("Export your data in standard, portable formats", comment: "Privacy policy - data portability description"))
                PolicyRow(title: NSLocalizedString("Control Communications", comment: "Privacy policy - control communications privacy right"), description: NSLocalizedString("Manage notification preferences and marketing communications", comment: "Privacy policy - control communications description"))
                PolicyRow(title: NSLocalizedString("Withdraw Consent", comment: "Privacy policy - withdraw consent privacy right"), description: NSLocalizedString("Revoke previously given permissions at any time", comment: "Privacy policy - withdraw consent description"))
            } header: {
                Text(NSLocalizedString("Your Privacy Rights", comment: "Privacy policy - your privacy rights section header"))
            }
            
            Section {
                PolicyRow(title: NSLocalizedString("No Payment Storage", comment: "Privacy policy - no payment storage policy"), description: NSLocalizedString("We do not store credit card or banking information", comment: "Privacy policy - no payment storage description"))
                PolicyRow(title: NSLocalizedString("App Store Processing", comment: "Privacy policy - app store processing policy"), description: NSLocalizedString("All payments are securely processed by Apple", comment: "Privacy policy - app store processing description"))
                PolicyRow(title: NSLocalizedString("Purchase Verification", comment: "Privacy policy - purchase verification policy"), description: NSLocalizedString("We may verify purchases through Apple's secure servers", comment: "Privacy policy - purchase verification description"))
                PolicyRow(title: NSLocalizedString("Subscription Management", comment: "Privacy policy - subscription management policy"), description: NSLocalizedString("Billing history is maintained by Apple, not BandSync", comment: "Privacy policy - subscription management description"))
            } header: {
                Text(NSLocalizedString("Payment Information", comment: "Privacy policy - payment information section header"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Age Requirements", comment: "Privacy policy - age requirements title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("BandSync is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.", comment: "Privacy policy - age requirements description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Parental Responsibility", comment: "Privacy policy - parental responsibility title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("If you believe a child under 13 has provided us with personal information, please contact us immediately so we can delete it.", comment: "Privacy policy - parental responsibility description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Children's Privacy", comment: "Privacy policy - children's privacy section header"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Policy Updates", comment: "Privacy policy - policy updates title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We may update this privacy policy periodically to reflect changes in our practices or legal requirements. We will notify users of significant changes through the app.", comment: "Privacy policy - policy updates description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Continued Use", comment: "Privacy policy - continued use title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("Your continued use of BandSync after policy updates constitutes acceptance of the revised terms.", comment: "Privacy policy - continued use description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Policy Changes", comment: "Privacy policy - policy changes section header"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Best Efforts Commitment", comment: "Privacy policy - best efforts commitment title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We are committed to protecting your privacy and implement industry-standard security measures. However, no system is completely secure, and we cannot guarantee absolute security.", comment: "Privacy policy - best efforts commitment description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Data Backup Recommendation", comment: "Privacy policy - data backup recommendation title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We recommend maintaining your own backups of important data. While we strive to protect and preserve your information, technical issues can occasionally occur.", comment: "Privacy policy - data backup recommendation description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Third-Party Services", comment: "Privacy policy - third-party services title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("While we carefully select trusted partners, we cannot control the privacy practices of third-party services. Please review their privacy policies as well.", comment: "Privacy policy - third-party services description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Important Notices", comment: "Privacy policy - important notices section header"))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Last updated: January 2025", comment: "Privacy policy - last updated footer"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("For privacy-related questions, please contact our support team through the app.", comment: "Privacy policy - contact support footer"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("We are committed to transparency and protecting your personal information.", comment: "Privacy policy - commitment footer"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(NSLocalizedString("Privacy Policy", comment: "Navigation title for privacy policy view"))
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
