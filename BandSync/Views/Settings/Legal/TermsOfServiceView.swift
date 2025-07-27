import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        List {
            Section {
                Text("Welcome to BandSync! These terms outline how you can use our app and the services we provide. By using BandSync, you agree to these terms.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("Welcome".localized)
            }
            
            Section {
                TermRow(title: "Age Requirement", description: "You must be at least 13 years old to use BandSync")
                TermRow(title: "Account Security", description: "Keep your login credentials secure and notify us of any unauthorized access")
                TermRow(title: "Accurate Information", description: "Provide truthful information when creating your account")
                TermRow(title: "Respectful Use", description: "Use BandSync for legitimate band management and collaboration")
                TermRow(title: "Compliance", description: "Follow all applicable laws and regulations in your jurisdiction")
            } header: {
                Text("Your Responsibilities".localized)
            }
            
            Section {
                TermRow(title: "Service Availability", description: "We strive to maintain reliable service but may experience occasional downtime")
                TermRow(title: "Feature Updates", description: "We regularly improve features and may add or modify functionality")
                TermRow(title: "Data Backup", description: "We recommend regularly backing up important data")
                TermRow(title: "Third-Party Integration", description: "Google Drive and other integrations are subject to their respective terms")
                TermRow(title: "Customer Support", description: "We provide support through our in-app contact system")
            } header: {
                Text("Our Services".localized)
            }
            
            Section {
                TermRow(title: "Your Content", description: "You own all band data, music, and content you create in BandSync")
                TermRow(title: "App License", description: "You grant us permission to process your data to provide app features")
                TermRow(title: "Respectful Sharing", description: "Only share content you have permission to share")
                TermRow(title: "Content Standards", description: "Keep all content appropriate and respectful")
            } header: {
                Text("Content & Data".localized)
            }
            
            Section {
                TermRow(title: "Professional Communication", description: "Maintain respectful interactions with team members")
                TermRow(title: "No Harassment", description: "Harassment or inappropriate behavior is not permitted")
                TermRow(title: "Constructive Collaboration", description: "Use BandSync to enhance your band's productivity")
                TermRow(title: "Privacy Respect", description: "Respect other users' privacy and personal information")
                TermRow(title: "Team Guidelines", description: "Follow your band leader's guidelines and group rules")
            } header: {
                Text("Community Standards".localized)
            }
            
            Section {
                TermRow(title: "Account Deletion", description: "You may delete your account at any time through app settings")
                TermRow(title: "Service Termination", description: "We may terminate accounts that violate these terms")
                TermRow(title: "Data Handling", description: "Upon termination, your data will be handled according to our Privacy Policy")
                TermRow(title: "Continuing Obligations", description: "Some provisions of these terms continue after termination")
            } header: {
                Text("Account Management".localized)
            }
            
            Section {
                TermRow(title: "App Store Billing", description: "All subscriptions and purchases are processed through the App Store")
                TermRow(title: "Subscription Management", description: "Manage subscriptions through your Apple ID account settings")
                TermRow(title: "Automatic Renewal", description: "Subscriptions automatically renew unless cancelled in App Store")
                TermRow(title: "Refund Policy", description: "Refunds are subject to Apple's App Store refund policy")
                TermRow(title: "Price Changes", description: "We may update prices with advance notice for new purchases")
                TermRow(title: "Free Features", description: "Basic features remain available to all users")
            } header: {
                Text("Billing & Subscriptions".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Service Limitations".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("BandSync is provided on an \"as is\" basis. While we strive to provide reliable and secure service, we cannot guarantee that the app will always be available or free from technical issues.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("User Responsibility".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("You are responsible for maintaining backups of important data and ensuring your account remains secure. We recommend using multiple backup methods for critical information.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Technical Support".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We provide technical support through our in-app contact system and strive to resolve issues promptly. Response times may vary based on the complexity of the issue.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Service Expectations".localized)
            }
            
            Section {
                TermRow(title: "Limitation of Liability", description: "Our liability is limited to the extent permitted by applicable law")
                TermRow(title: "Service Availability", description: "We make reasonable efforts to maintain service availability")
                TermRow(title: "Data Security", description: "We implement industry-standard security measures")
                TermRow(title: "User Support", description: "We provide reasonable technical support and assistance")
            } header: {
                Text("Legal Framework".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dispute Resolution".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("If you have any concerns or disputes, please contact our support team first. We are committed to resolving issues fairly and promptly.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Governing Law".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("These terms are governed by applicable law in your jurisdiction. Any legal disputes will be handled according to local laws and regulations.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Updates and Changes".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We may update these terms occasionally. Significant changes will be communicated through the app with advance notice. Your continued use constitutes acceptance of updated terms.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Legal Information".localized)
            }
            
            Section {
                Text("These terms constitute the complete agreement between you and BandSync regarding your use of our services. We are committed to providing a positive experience for all users.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
            } header: {
                Text("Complete Agreement".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last updated: January 2025".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("For questions about these terms, please contact our support team through the app.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("We appreciate your trust in BandSync and are committed to providing excellent service.".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Terms of Service".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TermRow: View {
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

#Preview {
    NavigationView {
        TermsOfServiceView()
    }
}
