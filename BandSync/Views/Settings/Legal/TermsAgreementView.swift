import SwiftUI

struct TermsAgreementView: View {
    @State private var hasAgreedToTerms = false
    @State private var hasAgreedToPrivacy = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    
    let onAgreementComplete: () -> Void
    
    var isAgreementComplete: Bool {
        hasAgreedToTerms && hasAgreedToPrivacy
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 16) {
                        // App Logo and Welcome
                        VStack(spacing: 12) {
                            Image("bandlogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            Text(NSLocalizedString("Welcome to BandSync", comment: "Welcome title for terms agreement"))
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(NSLocalizedString("Before you start, please review and accept our terms and privacy policy.", comment: "Description for terms agreement requirement"))
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, max(20, geometry.safeAreaInsets.top))
                        
                        // Agreement Section
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                // Terms of Service Agreement
                                AgreementRow(
                                    isChecked: hasAgreedToTerms,
                                    title: NSLocalizedString("Terms of Service", comment: "Title for Terms of Service"),
                                    description: NSLocalizedString("I agree to the Terms of Service", comment: "Checkbox description for Terms of Service agreement"),
                                    onToggle: { hasAgreedToTerms.toggle() },
                                    onViewDocument: { showTermsSheet = true }
                                )
                                
                                // Privacy Policy Agreement
                                AgreementRow(
                                    isChecked: hasAgreedToPrivacy,
                                    title: NSLocalizedString("Privacy Policy", comment: "Title for Privacy Policy"),
                                    description: NSLocalizedString("I agree to the Privacy Policy", comment: "Checkbox description for Privacy Policy agreement"),
                                    onToggle: { hasAgreedToPrivacy.toggle() },
                                    onViewDocument: { showPrivacySheet = true }
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Information Notice
                            VStack(spacing: 12) {
                                Text(NSLocalizedString("Important Information", comment: "Section title for important information"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    InfoRow(icon: "shield.checkered", text: NSLocalizedString("Your data is protected with industry-standard security", comment: "Information about data security"))
                                    InfoRow(icon: "person.crop.circle.badge.checkmark", text: NSLocalizedString("You maintain full control over your information", comment: "Information about data control"))
                                    InfoRow(icon: "arrow.down.circle", text: NSLocalizedString("You can export your data anytime", comment: "Information about data export"))
                                    InfoRow(icon: "trash.circle", text: NSLocalizedString("Delete your account and data whenever you choose", comment: "Information about data deletion"))
                                    InfoRow(icon: "envelope.circle", text: NSLocalizedString("Contact support for any questions or concerns", comment: "Information about support contact"))
                                }
                                
                                Text(NSLocalizedString("Service Features", comment: "Section title for service features"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ServiceRow(text: NSLocalizedString("• Secure band collaboration and coordination", comment: "Service feature 1"))
                                    ServiceRow(text: NSLocalizedString("• Event scheduling and attendance tracking", comment: "Service feature 2"))
                                    ServiceRow(text: NSLocalizedString("• Financial expense management", comment: "Service feature 3"))
                                    ServiceRow(text: NSLocalizedString("• Document sharing via Google Drive", comment: "Service feature 4"))
                                    ServiceRow(text: NSLocalizedString("• Cross-device synchronization", comment: "Service feature 5"))
                                    ServiceRow(text: NSLocalizedString("• Regular feature updates and improvements", comment: "Service feature 6"))
                                }
                                
                                Text(NSLocalizedString("Your Rights", comment: "Section title for user rights"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    RightRow(text: NSLocalizedString("• Access and download your personal data", comment: "User right 1"))
                                    RightRow(text: NSLocalizedString("• Correct any inaccurate information", comment: "User right 2"))
                                    RightRow(text: NSLocalizedString("• Request deletion of your account", comment: "User right 3"))
                                    RightRow(text: NSLocalizedString("• Control notification preferences", comment: "User right 4"))
                                    RightRow(text: NSLocalizedString("• Contact support for assistance", comment: "User right 5"))
                                }
                                
                                Text(NSLocalizedString("By continuing, you acknowledge that you have read and understood our terms and privacy policy. You can review these documents anytime in the app settings.", comment: "Acknowledgment text for terms agreement"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Continue Button
                        Button(action: {
                            if isAgreementComplete {
                                // Record user consent
                                LegalConsentTracker.shared.recordUserConsent()
                                onAgreementComplete()
                            }
                        }) {
                            HStack {
                                Text(NSLocalizedString("Get Started", comment: "Button text to get started with the app"))
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                if isAgreementComplete {
                                    Image(systemName: "arrow.right")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isAgreementComplete ? Color.accentColor : Color.gray)
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.2), value: isAgreementComplete)
                        }
                        .disabled(!isAgreementComplete)
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 32)
                        .padding(.top, 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showTermsSheet) {
            NavigationView {
                TermsOfServiceView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to dismiss terms view")) {
                                showTermsSheet = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            NavigationView {
                PrivacyPolicyView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to dismiss privacy policy view")) {
                                showPrivacySheet = false
                            }
                        }
                    }
            }
        }
    }
}

struct AgreementRow: View {
    let isChecked: Bool
    let title: String
    let description: String
    let onToggle: () -> Void
    let onViewDocument: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Document Title
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(NSLocalizedString("Read", comment: "Button to read document")) {
                    onViewDocument()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            // Agreement Checkbox
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundColor(isChecked ? .accentColor : .gray)
                        .animation(.easeInOut(duration: 0.2), value: isChecked)
                    
                    Text(description)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ServiceRow: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct RightRow: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

// Helper function to check if user has agreed to terms
extension TermsAgreementView {
    static func hasUserAgreedToTerms() -> Bool {
        return LegalConsentTracker.shared.hasUserConsented()
    }
    
    static func getTermsAgreementDate() -> Date? {
        return LegalConsentTracker.shared.getConsentDate()
    }
    
    static func resetTermsAgreement() {
        LegalConsentTracker.shared.resetConsent()
    }
    
    /// Gets detailed consent information for record keeping
    static func getConsentRecord() -> LegalConsentRecord? {
        return LegalConsentTracker.shared.getConsentRecord()
    }
}

#Preview("Default") {
    TermsAgreementView {
        print("User agreed to terms")
    }
}

#Preview("iPhone SE") {
    TermsAgreementView {
        print("User agreed to terms")
    }
}

#Preview("Large Device") {
    TermsAgreementView {
        print("User agreed to terms")
    }
}
