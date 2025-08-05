import SwiftUI

struct GDPRComplianceView: View {
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("BandSync is committed to complying with the General Data Protection Regulation (GDPR) and similar privacy laws. This section explains your rights and how we protect your data.", comment: "GDPR compliance overview description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Our Commitment to GDPR", comment: "Section header for GDPR commitment"))
            }
            
            Section {
                GDPRRightRow(
                    title: NSLocalizedString("Right to be Informed", comment: "GDPR right - right to be informed"),
                    description: NSLocalizedString("Clear, transparent information about how we collect and use your data", comment: "Description of right to be informed"),
                    action: NSLocalizedString("Detailed in our Privacy Policy", comment: "Action for right to be informed")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right of Access", comment: "GDPR right - right of access"),
                    description: NSLocalizedString("Request copies of your personal data and understand how it's processed", comment: "Description of right of access"),
                    action: NSLocalizedString("Contact Support or export data in app", comment: "Action for right of access")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right to Rectification", comment: "GDPR right - right to rectification"),
                    description: NSLocalizedString("Correct any inaccurate or incomplete personal data", comment: "Description of right to rectification"),
                    action: NSLocalizedString("Update through App Settings or contact Support", comment: "Action for right to rectification")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right to Erasure", comment: "GDPR right - right to erasure"),
                    description: NSLocalizedString("Request deletion of your personal data when appropriate", comment: "Description of right to erasure"),
                    action: NSLocalizedString("Delete Account in Settings or contact Support", comment: "Action for right to erasure")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right to Restrict Processing", comment: "GDPR right - right to restrict processing"),
                    description: NSLocalizedString("Limit how we process your data in certain circumstances", comment: "Description of right to restrict processing"),
                    action: NSLocalizedString("Contact Support for specific requests", comment: "Action for right to restrict processing")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right to Data Portability", comment: "GDPR right - right to data portability"),
                    description: NSLocalizedString("Receive your personal data in a structured, machine-readable format", comment: "Description of right to data portability"),
                    action: NSLocalizedString("Use Export Data feature or contact Support", comment: "Action for right to data portability")
                )
                GDPRRightRow(
                    title: NSLocalizedString("Right to Object", comment: "GDPR right - right to object"),
                    description: NSLocalizedString("Object to processing of your personal data in certain situations", comment: "Description of right to object"),
                    action: NSLocalizedString("Contact Support to discuss your concerns", comment: "Action for right to object")
                )
            } header: {
                Text(NSLocalizedString("Your GDPR Rights", comment: "Section header for GDPR rights"))
            }
            
            Section {
                ComplianceRow(title: NSLocalizedString("Lawful Basis for Processing", comment: "GDPR principle - lawful basis for processing"), description: NSLocalizedString("We process data based on legitimate interests, user consent, and contractual necessity", comment: "Description of lawful basis for processing"))
                ComplianceRow(title: NSLocalizedString("Data Minimization", comment: "GDPR principle - data minimization"), description: NSLocalizedString("We collect only the data necessary to provide our services", comment: "Description of data minimization"))
                ComplianceRow(title: NSLocalizedString("Purpose Limitation", comment: "GDPR principle - purpose limitation"), description: NSLocalizedString("Your data is used only for the purposes clearly communicated to you", comment: "Description of purpose limitation"))
                ComplianceRow(title: NSLocalizedString("Storage Limitation", comment: "GDPR principle - storage limitation"), description: NSLocalizedString("We retain data only as long as necessary to fulfill stated purposes", comment: "Description of storage limitation"))
                ComplianceRow(title: NSLocalizedString("Data Security", comment: "GDPR principle - data security"), description: NSLocalizedString("We implement appropriate technical and organizational security measures", comment: "Description of data security"))
                ComplianceRow(title: NSLocalizedString("Accountability", comment: "GDPR principle - accountability"), description: NSLocalizedString("We maintain records and can demonstrate our compliance efforts", comment: "Description of accountability"))
            } header: {
                Text(NSLocalizedString("GDPR Compliance Principles", comment: "Section header for GDPR compliance principles"))
            }
            
            Section {
                DataRow(type: NSLocalizedString("Account Information", comment: "Data type - account information"), retention: NSLocalizedString("Until account deletion or 3 years of inactivity", comment: "Retention period for account information"), purpose: NSLocalizedString("User authentication and app personalization", comment: "Purpose of account information"))
                DataRow(type: NSLocalizedString("Band Coordination Data", comment: "Data type - band coordination data"), retention: NSLocalizedString("Until manually deleted by user or band admin", comment: "Retention period for band coordination data"), purpose: NSLocalizedString("Team collaboration and task management", comment: "Purpose of band coordination data"))
                DataRow(type: NSLocalizedString("Event & Calendar Data", comment: "Data type - event and calendar data"), retention: NSLocalizedString("Until manually deleted by user", comment: "Retention period for event and calendar data"), purpose: NSLocalizedString("Schedule management and coordination", comment: "Purpose of event and calendar data"))
                DataRow(type: NSLocalizedString("Financial Records", comment: "Data type - financial records"), retention: NSLocalizedString("Until manually deleted by user", comment: "Retention period for financial records"), purpose: NSLocalizedString("Expense tracking and financial management", comment: "Purpose of financial records"))
                DataRow(type: NSLocalizedString("Usage Analytics", comment: "Data type - usage analytics"), retention: NSLocalizedString("Maximum 24 months, then anonymized", comment: "Retention period for usage analytics"), purpose: NSLocalizedString("App improvement and performance optimization", comment: "Purpose of usage analytics"))
                DataRow(type: NSLocalizedString("Support Communications", comment: "Data type - support communications"), retention: NSLocalizedString("Maximum 3 years for service quality", comment: "Retention period for support communications"), purpose: NSLocalizedString("Customer support and service improvement", comment: "Purpose of support communications"))
            } header: {
                Text(NSLocalizedString("Data Retention Periods", comment: "Section header for data retention periods"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ProcessorRow(name: NSLocalizedString("Firebase (Google LLC)", comment: "Data processor - Firebase"), purpose: NSLocalizedString("Secure data storage, authentication, and real-time synchronization", comment: "Purpose of Firebase"), location: NSLocalizedString("EU/US with Standard Contractual Clauses", comment: "Location and legal basis for Firebase"))
                    ProcessorRow(name: NSLocalizedString("Google Drive API", comment: "Data processor - Google Drive API"), purpose: NSLocalizedString("Document storage and sharing integration", comment: "Purpose of Google Drive API"), location: NSLocalizedString("EU/US with Standard Contractual Clauses", comment: "Location and legal basis for Google Drive API"))
                    ProcessorRow(name: NSLocalizedString("Apple App Store", comment: "Data processor - Apple App Store"), purpose: NSLocalizedString("App distribution and subscription management", comment: "Purpose of Apple App Store"), location: NSLocalizedString("Global with appropriate safeguards", comment: "Location and legal basis for Apple App Store"))
                }
            } header: {
                Text(NSLocalizedString("International Data Transfers", comment: "Section header for international data transfers"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Contact Information", comment: "Subsection title - contact information"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("For GDPR-related requests or questions, please contact our support team through the in-app contact feature. We aim to respond to all requests within 30 days.", comment: "Description of contact information for GDPR requests"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Supervisory Authority Rights", comment: "Subsection title - supervisory authority rights"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("You have the right to lodge a complaint with your local data protection authority if you believe we have not handled your data appropriately.", comment: "Description of supervisory authority rights"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Exercising Your Rights", comment: "Section header for exercising rights"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Ongoing Compliance Efforts", comment: "Subsection title - ongoing compliance efforts"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We regularly review and update our data protection practices to ensure ongoing GDPR compliance. This includes regular security assessments, staff training, and policy updates.", comment: "Description of ongoing compliance efforts"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Third-Party Compliance", comment: "Subsection title - third-party compliance"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We work only with service providers who demonstrate strong data protection practices and GDPR compliance. We maintain data processing agreements with all third-party processors.", comment: "Description of third-party compliance"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Transparency Commitment", comment: "Subsection title - transparency commitment"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We are committed to transparency in our data handling practices. If you have questions about how we process your data, please don't hesitate to contact us.", comment: "Description of transparency commitment"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Our Ongoing Commitment", comment: "Section header for ongoing commitment"))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Last updated: January 2025", comment: "Footer text - last updated date"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("For GDPR-related requests, use the Contact Support feature in Settings.", comment: "Footer text - GDPR request instructions"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("We are committed to protecting your privacy rights and maintaining GDPR compliance.", comment: "Footer text - privacy commitment"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(NSLocalizedString("GDPR Compliance", comment: "Navigation title for GDPR compliance view"))
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
            Text(NSLocalizedString("How to exercise: ", comment: "GDPR rights exercise instruction") + action.localized)
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
            Text(NSLocalizedString("Retention: ", comment: "GDPR data retention label") + retention.localized)
                .font(.caption)
                .foregroundColor(.orange)
            Text(NSLocalizedString("Purpose: ", comment: "GDPR data purpose label") + purpose.localized)
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
            Text(NSLocalizedString("Purpose: \(purpose.localized)", comment: "GDPR compliance - purpose label"))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(NSLocalizedString("Legal basis: \(location.localized)", comment: "GDPR compliance - legal basis label"))
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
