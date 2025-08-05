import SwiftUI

struct CookiePolicyView: View {
    var body: some View {
        List {
            Section {
                Text(NSLocalizedString("BandSync uses minimal data storage and analytics to provide a great user experience. This policy explains our approach to data storage, cookies, and similar technologies.", comment: "Cookie policy overview description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Data Storage Overview", comment: "Section header for data storage overview"))
            }
            
            Section {
                CookieRow(title: NSLocalizedString("Authentication Tokens", comment: "Cookie type - authentication tokens"), purpose: NSLocalizedString("Keep you securely logged in to your account", comment: "Purpose of authentication tokens"), category: NSLocalizedString("Essential", comment: "Cookie category - essential"))
                CookieRow(title: NSLocalizedString("User Preferences", comment: "Cookie type - user preferences"), purpose: NSLocalizedString("Remember your app settings and customizations", comment: "Purpose of user preferences"), category: NSLocalizedString("Essential", comment: "Cookie category - essential"))
                CookieRow(title: NSLocalizedString("Session Data", comment: "Cookie type - session data"), purpose: NSLocalizedString("Maintain your current session and app state", comment: "Purpose of session data"), category: NSLocalizedString("Essential", comment: "Cookie category - essential"))
                CookieRow(title: NSLocalizedString("Offline Cache", comment: "Cookie type - offline cache"), purpose: NSLocalizedString("Store data locally for offline access and faster loading", comment: "Purpose of offline cache"), category: NSLocalizedString("Essential", comment: "Cookie category - essential"))
                CookieRow(title: NSLocalizedString("Security Tokens", comment: "Cookie type - security tokens"), purpose: NSLocalizedString("Protect your account from unauthorized access", comment: "Purpose of security tokens"), category: NSLocalizedString("Essential", comment: "Cookie category - essential"))
            } header: {
                Text(NSLocalizedString("Essential Data Storage", comment: "Section header for essential data storage"))
            }
            
            Section {
                CookieRow(title: NSLocalizedString("Performance Monitoring", comment: "Cookie type - performance monitoring"), purpose: NSLocalizedString("Track app performance and identify technical issues", comment: "Purpose of performance monitoring"), category: NSLocalizedString("Analytics", comment: "Cookie category - analytics"))
                CookieRow(title: NSLocalizedString("Feature Usage", comment: "Cookie type - feature usage"), purpose: NSLocalizedString("Understand which features are most helpful to users", comment: "Purpose of feature usage tracking"), category: NSLocalizedString("Analytics", comment: "Cookie category - analytics"))
                CookieRow(title: NSLocalizedString("Error Reporting", comment: "Cookie type - error reporting"), purpose: NSLocalizedString("Automatically report crashes and bugs for quick fixes", comment: "Purpose of error reporting"), category: NSLocalizedString("Analytics", comment: "Cookie category - analytics"))
                CookieRow(title: NSLocalizedString("Usage Statistics", comment: "Cookie type - usage statistics"), purpose: NSLocalizedString("Improve app design and user experience", comment: "Purpose of usage statistics"), category: NSLocalizedString("Analytics", comment: "Cookie category - analytics"))
            } header: {
                Text(NSLocalizedString("Analytics & Improvement", comment: "Section header for analytics and improvement"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    ControlRow(title: NSLocalizedString("Essential Data", comment: "Control option - essential data"), description: NSLocalizedString("Required for app functionality and cannot be disabled", comment: "Description for essential data control"))
                    ControlRow(title: NSLocalizedString("Analytics Data", comment: "Control option - analytics data"), description: NSLocalizedString("Can be controlled through iOS Privacy Settings", comment: "Description for analytics data control"))
                    ControlRow(title: NSLocalizedString("App Cache", comment: "Control option - app cache"), description: NSLocalizedString("Can be cleared through BandSync Settings", comment: "Description for app cache control"))
                    ControlRow(title: NSLocalizedString("Account Data", comment: "Control option - account data"), description: NSLocalizedString("Managed through your account settings", comment: "Description for account data control"))
                }
            } header: {
                Text(NSLocalizedString("Your Control Options", comment: "Section header for control options"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("iOS Privacy Settings", comment: "Data management option - iOS privacy settings"))
                        .font(.body)
                        .fontWeight(.medium)
                    Text(NSLocalizedString("Control app tracking and analytics through Settings > Privacy & Security > Analytics & Improvements", comment: "Instructions for iOS privacy settings"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("BandSync Settings", comment: "Data management option - BandSync settings"))
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    Text(NSLocalizedString("Clear app cache and manage data storage through the Settings tab in BandSync", comment: "Instructions for BandSync settings"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Account Management", comment: "Data management option - account management"))
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    Text(NSLocalizedString("Export your data or delete your account at any time through Account Settings", comment: "Instructions for account management"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Managing Your Data", comment: "Section header for managing data"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    ThirdPartyRow(name: NSLocalizedString("Firebase Analytics", comment: "Third party service - Firebase Analytics"), provider: NSLocalizedString("Google LLC", comment: "Provider - Google LLC"), purpose: NSLocalizedString("App performance and usage analytics", comment: "Purpose of Firebase Analytics"))
                    ThirdPartyRow(name: NSLocalizedString("Firebase Crashlytics", comment: "Third party service - Firebase Crashlytics"), provider: NSLocalizedString("Google LLC", comment: "Provider - Google LLC"), purpose: NSLocalizedString("Crash reporting and error tracking", comment: "Purpose of Firebase Crashlytics"))
                    ThirdPartyRow(name: NSLocalizedString("Google Drive API", comment: "Third party service - Google Drive API"), provider: NSLocalizedString("Google LLC", comment: "Provider - Google LLC"), purpose: NSLocalizedString("Document storage and sharing", comment: "Purpose of Google Drive API"))
                    ThirdPartyRow(name: NSLocalizedString("Apple Analytics", comment: "Third party service - Apple Analytics"), provider: NSLocalizedString("Apple Inc.", comment: "Provider - Apple Inc."), purpose: NSLocalizedString("App Store analytics and performance metrics", comment: "Purpose of Apple Analytics"))
                }
            } header: {
                Text(NSLocalizedString("Third-Party Services", comment: "Section header for third-party services"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Notification of Changes", comment: "Policy update topic - notification of changes"))
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(NSLocalizedString("We will update this policy when we make changes to our data storage practices. Significant changes will be communicated through the app with advance notice.", comment: "Description of policy change notifications"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Continued Use", comment: "Policy update topic - continued use"))
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    Text(NSLocalizedString("Your continued use of BandSync after policy updates indicates acceptance of the revised practices.", comment: "Description of continued use implications"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Policy Updates", comment: "Section header for policy updates"))
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Data Security Commitment", comment: "Important info topic - data security commitment"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("We implement industry-standard security measures to protect stored data. However, we recommend maintaining your own backups of important information as an additional precaution.", comment: "Description of data security commitment"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Third-Party Data Practices", comment: "Important info topic - third-party data practices"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("While we carefully select trusted service providers, we recommend reviewing their privacy policies as well. We work only with providers who meet high security and privacy standards.", comment: "Description of third-party data practices"))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("User Responsibility", comment: "Important info topic - user responsibility"))
                        .font(.body)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("Users are encouraged to understand and utilize available privacy controls on their devices and within the app to customize their data sharing preferences.", comment: "Description of user responsibility"))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(NSLocalizedString("Important Information", comment: "Section header for important information"))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Last updated: January 2025", comment: "Footer text - last updated date"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("For questions about data storage practices, contact our support team through the app.", comment: "Footer text - contact for questions"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("We are committed to transparent and responsible data handling practices.", comment: "Footer text - commitment statement"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle(NSLocalizedString("Data & Storage Policy", comment: "Navigation title for cookie policy view"))
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
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(category == NSLocalizedString("Essential", comment: "Cookie category - essential") ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(category == NSLocalizedString("Essential", comment: "Cookie category - essential") ? .green : .blue)
                    .cornerRadius(4)
            }
            Text(purpose)
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
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            Text(description)
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
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(provider)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Text(purpose)
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
