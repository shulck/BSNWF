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
                            
                            Text("Welcome to BandSync".localized)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Before you start, please review and accept our terms and privacy policy.".localized)
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
                                    title: "Terms of Service".localized,
                                    description: "I agree to the Terms of Service".localized,
                                    onToggle: { hasAgreedToTerms.toggle() },
                                    onViewDocument: { showTermsSheet = true }
                                )
                                
                                // Privacy Policy Agreement
                                AgreementRow(
                                    isChecked: hasAgreedToPrivacy,
                                    title: "Privacy Policy".localized,
                                    description: "I agree to the Privacy Policy".localized,
                                    onToggle: { hasAgreedToPrivacy.toggle() },
                                    onViewDocument: { showPrivacySheet = true }
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Information Notice
                            VStack(spacing: 12) {
                                Text("Important Information".localized)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    InfoRow(icon: "shield.checkered", text: "Your data is protected with industry-standard security".localized)
                                    InfoRow(icon: "person.crop.circle.badge.checkmark", text: "You maintain full control over your information".localized)
                                    InfoRow(icon: "arrow.down.circle", text: "You can export your data anytime".localized)
                                    InfoRow(icon: "trash.circle", text: "Delete your account and data whenever you choose".localized)
                                    InfoRow(icon: "envelope.circle", text: "Contact support for any questions or concerns".localized)
                                }
                                
                                Text("Service Features".localized)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ServiceRow(text: "• Secure band collaboration and coordination".localized)
                                    ServiceRow(text: "• Event scheduling and attendance tracking".localized)
                                    ServiceRow(text: "• Financial expense management".localized)
                                    ServiceRow(text: "• Document sharing via Google Drive".localized)
                                    ServiceRow(text: "• Cross-device synchronization".localized)
                                    ServiceRow(text: "• Regular feature updates and improvements".localized)
                                }
                                
                                Text("Your Rights".localized)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    RightRow(text: "• Access and download your personal data".localized)
                                    RightRow(text: "• Correct any inaccurate information".localized)
                                    RightRow(text: "• Request deletion of your account".localized)
                                    RightRow(text: "• Control notification preferences".localized)
                                    RightRow(text: "• Contact support for assistance".localized)
                                }
                                
                                Text("By continuing, you acknowledge that you have read and understood our terms and privacy policy. You can review these documents anytime in the app settings.".localized)
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
                                Text("Get Started".localized)
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
                            Button("Done".localized) {
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
                            Button("Done".localized) {
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
                Button("Read".localized) {
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
