import SwiftUI

struct GDPRComplianceView: View {
    var body: some View {
        List {
            Section {
                Text("BandSync is committed to complying with the General Data Protection Regulation (GDPR) and similar privacy laws. This section explains your rights and how we protect your data.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("Our Commitment to GDPR".localized)
            }
            
            Section {
                GDPRRightRow(
                    title: "Right to be Informed".localized,
                    description: "Clear, transparent information about how we collect and use your data".localized,
                    action: "Detailed in our Privacy Policy".localized
                )
                GDPRRightRow(
                    title: "Right of Access".localized,
                    description: "Request copies of your personal data and understand how it's processed".localized,
                    action: "Contact Support or export data in app".localized
                )
                GDPRRightRow(
                    title: "Right to Rectification".localized,
                    description: "Correct any inaccurate or incomplete personal data".localized,
                    action: "Update through App Settings or contact Support".localized
                )
                GDPRRightRow(
                    title: "Right to Erasure".localized,
                    description: "Request deletion of your personal data when appropriate".localized,
                    action: "Delete Account in Settings or contact Support".localized
                )
                GDPRRightRow(
                    title: "Right to Restrict Processing".localized,
                    description: "Limit how we process your data in certain circumstances".localized,
                    action: "Contact Support for specific requests".localized
                )
                GDPRRightRow(
                    title: "Right to Data Portability".localized,
                    description: "Receive your personal data in a structured, machine-readable format".localized,
                    action: "Use Export Data feature or contact Support".localized
                )
                GDPRRightRow(
                    title: "Right to Object".localized,
                    description: "Object to processing of your personal data in certain situations".localized,
                    action: "Contact Support to discuss your concerns".localized
                )
            } header: {
                Text("Your GDPR Rights".localized)
            }
            
            Section {
                ComplianceRow(title: "Lawful Basis for Processing".localized, description: "We process data based on legitimate interests, user consent, and contractual necessity".localized)
                ComplianceRow(title: "Data Minimization".localized, description: "We collect only the data necessary to provide our services".localized)
                ComplianceRow(title: "Purpose Limitation".localized, description: "Your data is used only for the purposes clearly communicated to you".localized)
                ComplianceRow(title: "Storage Limitation".localized, description: "We retain data only as long as necessary to fulfill stated purposes".localized)
                ComplianceRow(title: "Data Security".localized, description: "We implement appropriate technical and organizational security measures".localized)
                ComplianceRow(title: "Accountability".localized, description: "We maintain records and can demonstrate our compliance efforts".localized)
            } header: {
                Text("GDPR Compliance Principles".localized)
            }
            
            Section {
                DataRow(type: "Account Information".localized, retention: "Until account deletion or 3 years of inactivity".localized, purpose: "User authentication and app personalization".localized)
                DataRow(type: "Band Coordination Data".localized, retention: "Until manually deleted by user or band admin".localized, purpose: "Team collaboration and task management".localized)
                DataRow(type: "Event & Calendar Data".localized, retention: "Until manually deleted by user".localized, purpose: "Schedule management and coordination".localized)
                DataRow(type: "Financial Records".localized, retention: "Until manually deleted by user".localized, purpose: "Expense tracking and financial management".localized)
                DataRow(type: "Usage Analytics".localized, retention: "Maximum 24 months, then anonymized".localized, purpose: "App improvement and performance optimization".localized)
                DataRow(type: "Support Communications".localized, retention: "Maximum 3 years for service quality".localized, purpose: "Customer support and service improvement".localized)
            } header: {
                Text("Data Retention Periods".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ProcessorRow(name: "Firebase (Google LLC)".localized, purpose: "Secure data storage, authentication, and real-time synchronization".localized, location: "EU/US with Standard Contractual Clauses".localized)
                    ProcessorRow(name: "Google Drive API".localized, purpose: "Document storage and sharing integration".localized, location: "EU/US with Standard Contractual Clauses".localized)
                    ProcessorRow(name: "Apple App Store".localized, purpose: "App distribution and subscription management".localized, location: "Global with appropriate safeguards".localized)
                }
            } header: {
                Text("International Data Transfers".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Information".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("For GDPR-related requests or questions, please contact our support team through the in-app contact feature. We aim to respond to all requests within 30 days.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Supervisory Authority Rights".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("You have the right to lodge a complaint with your local data protection authority if you believe we have not handled your data appropriately.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Exercising Your Rights".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ongoing Compliance Efforts".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We regularly review and update our data protection practices to ensure ongoing GDPR compliance. This includes regular security assessments, staff training, and policy updates.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Third-Party Compliance".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We work only with service providers who demonstrate strong data protection practices and GDPR compliance. We maintain data processing agreements with all third-party processors.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Transparency Commitment".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We are committed to transparency in our data handling practices. If you have questions about how we process your data, please don't hesitate to contact us.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Our Ongoing Commitment".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last updated: January 2025".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("For GDPR-related requests, use the Contact Support feature in Settings.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("We are committed to protecting your privacy rights and maintaining GDPR compliance.".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("GDPR Compliance".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct GDPRRightRow: View {
    let title: String
    let description: String
    let action: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.localized)
                .font(.body)
                .fontWeight(.medium)
            Text(description.localized)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("How to exercise: \(action.localized)".localized)
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 2)
    }
}

struct ComplianceRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.localized)
                .font(.body)
                .fontWeight(.medium)
            Text(description.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct DataRow: View {
    let type: String
    let retention: String
    let purpose: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(type.localized)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            Text("Retention: \(retention.localized)".localized)
                .font(.caption)
                .foregroundColor(.orange)
            Text("Purpose: \(purpose.localized)".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ProcessorRow: View {
    let name: String
    let purpose: String
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.localized)
                .font(.body)
                .fontWeight(.medium)
            Text("Purpose: \(purpose.localized)".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Legal basis: \(location.localized)".localized)
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    NavigationView {
        GDPRComplianceView()
    }
}
