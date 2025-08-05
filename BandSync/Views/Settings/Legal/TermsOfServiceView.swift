import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("Welcome to BandSync! These terms outline how you can use our app and the services we provide. By using BandSync, you agree to these terms.", comment: "Terms of service - welcome description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Welcome", comment: "Terms of service - welcome section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Age Requirement", comment: "Terms of service - age requirement responsibility"), description: NSLocalizedString("You must be at least 13 years old to use BandSync", comment: "Terms of service - age requirement description"))
                TermRow(title: NSLocalizedString("Account Security", comment: "Terms of service - account security responsibility"), description: NSLocalizedString("Keep your login credentials secure and notify us of any unauthorized access", comment: "Terms of service - account security description"))
                TermRow(title: NSLocalizedString("Accurate Information", comment: "Terms of service - accurate information responsibility"), description: NSLocalizedString("Provide truthful information when creating your account", comment: "Terms of service - accurate information description"))
                TermRow(title: NSLocalizedString("Respectful Use", comment: "Terms of service - respectful use responsibility"), description: NSLocalizedString("Use BandSync for legitimate band management and collaboration", comment: "Terms of service - respectful use description"))
                TermRow(title: NSLocalizedString("Compliance", comment: "Terms of service - compliance responsibility"), description: NSLocalizedString("Follow all applicable laws and regulations in your jurisdiction", comment: "Terms of service - compliance description"))
            } header: {
                Text(NSLocalizedString("Your Responsibilities", comment: "Terms of service - your responsibilities section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Service Availability", comment: "Terms of service - service availability feature"), description: NSLocalizedString("We strive to maintain reliable service but may experience occasional downtime", comment: "Terms of service - service availability description"))
                TermRow(title: NSLocalizedString("Feature Updates", comment: "Terms of service - feature updates feature"), description: NSLocalizedString("We regularly improve features and may add or modify functionality", comment: "Terms of service - feature updates description"))
                TermRow(title: NSLocalizedString("Data Backup", comment: "Terms of service - data backup feature"), description: NSLocalizedString("We recommend regularly backing up important data", comment: "Terms of service - data backup description"))
                TermRow(title: NSLocalizedString("Third-Party Integration", comment: "Terms of service - third-party integration feature"), description: NSLocalizedString("Google Drive and other integrations are subject to their respective terms", comment: "Terms of service - third-party integration description"))
                TermRow(title: NSLocalizedString("Customer Support", comment: "Terms of service - customer support feature"), description: NSLocalizedString("We provide support through our in-app contact system", comment: "Terms of service - customer support description"))
            } header: {
                Text(NSLocalizedString("Our Services", comment: "Terms of service - our services section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Your Content", comment: "Terms of service - your content data policy"), description: NSLocalizedString("You own all band data, music, and content you create in BandSync", comment: "Terms of service - your content description"))
                TermRow(title: NSLocalizedString("App License", comment: "Terms of service - app license data policy"), description: NSLocalizedString("You grant us permission to process your data to provide app features", comment: "Terms of service - app license description"))
                TermRow(title: NSLocalizedString("Respectful Sharing", comment: "Terms of service - respectful sharing data policy"), description: NSLocalizedString("Only share content you have permission to share", comment: "Terms of service - respectful sharing description"))
                TermRow(title: NSLocalizedString("Content Standards", comment: "Terms of service - content standards data policy"), description: NSLocalizedString("Keep all content appropriate and respectful", comment: "Terms of service - content standards description"))
            } header: {
                Text(NSLocalizedString("Content & Data", comment: "Terms of service - content and data section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Professional Communication", comment: "Terms of service - professional communication standard"), description: NSLocalizedString("Maintain respectful interactions with team members", comment: "Terms of service - professional communication description"))
                TermRow(title: NSLocalizedString("No Harassment", comment: "Terms of service - no harassment standard"), description: NSLocalizedString("Harassment or inappropriate behavior is not permitted", comment: "Terms of service - no harassment description"))
                TermRow(title: NSLocalizedString("Constructive Collaboration", comment: "Terms of service - constructive collaboration standard"), description: NSLocalizedString("Use BandSync to enhance your band's productivity", comment: "Terms of service - constructive collaboration description"))
                TermRow(title: NSLocalizedString("Privacy Respect", comment: "Terms of service - privacy respect standard"), description: NSLocalizedString("Respect other users' privacy and personal information", comment: "Terms of service - privacy respect description"))
                TermRow(title: NSLocalizedString("Team Guidelines", comment: "Terms of service - team guidelines standard"), description: NSLocalizedString("Follow your band leader's guidelines and group rules", comment: "Terms of service - team guidelines description"))
            } header: {
                Text(NSLocalizedString("Community Standards", comment: "Terms of service - community standards section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Account Deletion", comment: "Terms of service - account deletion management"), description: NSLocalizedString("You may delete your account at any time through app settings", comment: "Terms of service - account deletion description"))
                TermRow(title: NSLocalizedString("Service Termination", comment: "Terms of service - service termination management"), description: NSLocalizedString("We may terminate accounts that violate these terms", comment: "Terms of service - service termination description"))
                TermRow(title: NSLocalizedString("Data Handling", comment: "Terms of service - data handling management"), description: NSLocalizedString("Upon termination, your data will be handled according to our Privacy Policy", comment: "Terms of service - data handling description"))
                TermRow(title: NSLocalizedString("Continuing Obligations", comment: "Terms of service - continuing obligations management"), description: NSLocalizedString("Some provisions of these terms continue after termination", comment: "Terms of service - continuing obligations description"))
            } header: {
                Text(NSLocalizedString("Account Management", comment: "Terms of service - account management section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("App Store Billing", comment: "Terms of service - app store billing subscription"), description: NSLocalizedString("All subscriptions and purchases are processed through the App Store", comment: "Terms of service - app store billing description"))
                TermRow(title: NSLocalizedString("Subscription Management", comment: "Terms of service - subscription management billing"), description: NSLocalizedString("Manage subscriptions through your Apple ID account settings", comment: "Terms of service - subscription management description"))
                TermRow(title: NSLocalizedString("Automatic Renewal", comment: "Terms of service - automatic renewal billing"), description: NSLocalizedString("Subscriptions automatically renew unless cancelled in App Store", comment: "Terms of service - automatic renewal description"))
                TermRow(title: NSLocalizedString("Refund Policy", comment: "Terms of service - refund policy billing"), description: NSLocalizedString("Refunds are subject to Apple's App Store refund policy", comment: "Terms of service - refund policy description"))
                TermRow(title: NSLocalizedString("Price Changes", comment: "Terms of service - price changes billing"), description: NSLocalizedString("We may update prices with advance notice for new purchases", comment: "Terms of service - price changes description"))
                TermRow(title: NSLocalizedString("Free Features", comment: "Terms of service - free features billing"), description: NSLocalizedString("Basic features remain available to all users", comment: "Terms of service - free features description"))
            } header: {
                Text(NSLocalizedString("Billing & Subscriptions", comment: "Terms of service - billing and subscriptions section header"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Service Limitations", comment: "Terms of service - service limitations title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("BandSync is provided on an \"as is\" basis. While we strive to provide reliable and secure service, we cannot guarantee that the app will always be available or free from technical issues.", comment: "Terms of service - service limitations description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("User Responsibility", comment: "Terms of service - user responsibility title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("You are responsible for maintaining backups of important data and ensuring your account remains secure. We recommend using multiple backup methods for critical information.", comment: "Terms of service - user responsibility description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Technical Support", comment: "Terms of service - technical support title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We provide technical support through our in-app contact system and strive to resolve issues promptly. Response times may vary based on the complexity of the issue.", comment: "Terms of service - technical support description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Service Expectations", comment: "Terms of service - service expectations section header"))
            }
            
            Section {
                TermRow(title: NSLocalizedString("Limitation of Liability", comment: "Terms of service - limitation of liability legal framework"), description: NSLocalizedString("Our liability is limited to the extent permitted by applicable law", comment: "Terms of service - limitation of liability description"))
                TermRow(title: NSLocalizedString("Service Availability", comment: "Terms of service - service availability legal framework"), description: NSLocalizedString("We make reasonable efforts to maintain service availability", comment: "Terms of service - service availability description"))
                TermRow(title: NSLocalizedString("Data Security", comment: "Terms of service - data security legal framework"), description: NSLocalizedString("We implement industry-standard security measures", comment: "Terms of service - data security description"))
                TermRow(title: NSLocalizedString("User Support", comment: "Terms of service - user support legal framework"), description: NSLocalizedString("We provide reasonable technical support and assistance", comment: "Terms of service - user support description"))
            } header: {
                Text(NSLocalizedString("Legal Framework", comment: "Terms of service - legal framework section header"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Dispute Resolution", comment: "Terms of service - dispute resolution title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("If you have any concerns or disputes, please contact our support team first. We are committed to resolving issues fairly and promptly.", comment: "Terms of service - dispute resolution description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Governing Law", comment: "Terms of service - governing law title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("These terms are governed by applicable law in your jurisdiction. Any legal disputes will be handled according to local laws and regulations.", comment: "Terms of service - governing law description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Updates and Changes", comment: "Terms of service - updates and changes title"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We may update these terms occasionally. Significant changes will be communicated through the app with advance notice. Your continued use constitutes acceptance of updated terms.", comment: "Terms of service - updates and changes description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Legal Information", comment: "Terms of service - legal information section header"))
            }
            
            Section {
                Text(NSLocalizedString("These terms constitute the complete agreement between you and BandSync regarding your use of our services. We are committed to providing a positive experience for all users.", comment: "Terms of service - complete agreement description"))
                    .font(.body)
                    .foregroundColor(.secondary)
            } header: {
                Text(NSLocalizedString("Complete Agreement", comment: "Terms of service - complete agreement section header"))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Last updated: January 2025", comment: "Terms of service - last updated footer"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("For questions about these terms, please contact our support team through the app.", comment: "Terms of service - contact support footer"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("We appreciate your trust in BandSync and are committed to providing excellent service.", comment: "Terms of service - appreciation footer"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(NSLocalizedString("Terms of Service", comment: "Navigation title for terms of service view"))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TermRow: View {
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
        TermsOfServiceView()
    }
}
