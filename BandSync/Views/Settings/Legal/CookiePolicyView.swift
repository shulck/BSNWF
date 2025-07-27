import SwiftUI

struct CookiePolicyView: View {
    var body: some View {
        List {
            Section {
                Text("BandSync uses minimal data storage and analytics to provide a great user experience. This policy explains our approach to data storage, cookies, and similar technologies.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("Data Storage Overview".localized)
            }
            
            Section {
                CookieRow(title: "Authentication Tokens".localized, purpose: "Keep you securely logged in to your account".localized, category: "Essential".localized)
                CookieRow(title: "User Preferences".localized, purpose: "Remember your app settings and customizations".localized, category: "Essential".localized)
                CookieRow(title: "Session Data".localized, purpose: "Maintain your current session and app state".localized, category: "Essential".localized)
                CookieRow(title: "Offline Cache".localized, purpose: "Store data locally for offline access and faster loading".localized, category: "Essential".localized)
                CookieRow(title: "Security Tokens".localized, purpose: "Protect your account from unauthorized access".localized, category: "Essential".localized)
            } header: {
                Text("Essential Data Storage".localized)
            }
            
            Section {
                CookieRow(title: "Performance Monitoring".localized, purpose: "Track app performance and identify technical issues".localized, category: "Analytics".localized)
                CookieRow(title: "Feature Usage".localized, purpose: "Understand which features are most helpful to users".localized, category: "Analytics".localized)
                CookieRow(title: "Error Reporting".localized, purpose: "Automatically report crashes and bugs for quick fixes".localized, category: "Analytics".localized)
                CookieRow(title: "Usage Statistics".localized, purpose: "Improve app design and user experience".localized, category: "Analytics".localized)
            } header: {
                Text("Analytics & Improvement".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ControlRow(title: "Essential Data".localized, description: "Required for app functionality and cannot be disabled".localized)
                    ControlRow(title: "Analytics Data".localized, description: "Can be controlled through iOS Privacy Settings".localized)
                    ControlRow(title: "App Cache".localized, description: "Can be cleared through BandSync Settings".localized)
                    ControlRow(title: "Account Data".localized, description: "Managed through your account settings".localized)
                }
            } header: {
                Text("Your Control Options".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("iOS Privacy Settings".localized)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Control app tracking and analytics through Settings > Privacy & Security > Analytics & Improvements".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("BandSync Settings".localized)
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    Text("Clear app cache and manage data storage through the Settings tab in BandSync".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Account Management".localized)
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    Text("Export your data or delete your account at any time through Account Settings".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Managing Your Data".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    ThirdPartyRow(name: "Firebase Analytics".localized, provider: "Google LLC".localized, purpose: "App performance and usage analytics".localized)
                    ThirdPartyRow(name: "Firebase Crashlytics".localized, provider: "Google LLC".localized, purpose: "Crash reporting and error tracking".localized)
                    ThirdPartyRow(name: "Google Drive API".localized, provider: "Google LLC".localized, purpose: "Document storage and sharing".localized)
                    ThirdPartyRow(name: "Apple Analytics".localized, provider: "Apple Inc.".localized, purpose: "App Store analytics and performance metrics".localized)
                }
            } header: {
                Text("Third-Party Services".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notification of Changes".localized)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("We will update this policy when we make changes to our data storage practices. Significant changes will be communicated through the app with advance notice.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Continued Use".localized)
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    Text("Your continued use of BandSync after policy updates indicates acceptance of the revised practices.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Policy Updates".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Security Commitment".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("We implement industry-standard security measures to protect stored data. However, we recommend maintaining your own backups of important information as an additional precaution.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Third-Party Data Practices".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("While we carefully select trusted service providers, we recommend reviewing their privacy policies as well. We work only with providers who meet high security and privacy standards.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("User Responsibility".localized)
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text("Users are encouraged to understand and utilize available privacy controls on their devices and within the app to customize their data sharing preferences.".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Important Information".localized)
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last updated: January 2025".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("For questions about data storage practices, contact our support team through the app.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("We are committed to transparent and responsible data handling practices.".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Data & Storage Policy".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CookieRow: View {
    let title: String
    let purpose: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title.localized)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(category.localized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(category == "Essential" ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(category == "Essential" ? .green : .blue)
                    .cornerRadius(4)
            }
            Text(purpose.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ControlRow: View {
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
    }
}

struct ThirdPartyRow: View {
    let name: String
    let provider: String
    let purpose: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name.localized)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(provider.localized)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Text(purpose.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        CookiePolicyView()
    }
}
