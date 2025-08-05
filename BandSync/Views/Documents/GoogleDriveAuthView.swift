import SwiftUI

struct GoogleDriveAuthView: View {
    @StateObject private var googleDriveService = GoogleDriveService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var authError: Error?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "icloud")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("connectGoogleDrive", comment: "Connect Google Drive title"))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("connectYourGoogleDriveAccountToSecurelyStore", comment: "Google Drive connection description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    GoogleDriveFeatureRow(icon: "lock.shield", title: NSLocalizedString("secureStorage", comment: "Secure storage feature title"), description: NSLocalizedString("yourDocumentsAreEncryptedAndSafelyStored", comment: "Secure storage description"))
                    GoogleDriveFeatureRow(icon: "person.2", title: NSLocalizedString("teamCollaboration", comment: "Team collaboration feature title"), description: NSLocalizedString("shareDocumentsWithBandMembers", comment: "Team collaboration description"))
                    GoogleDriveFeatureRow(icon: "folder.badge.plus", title: NSLocalizedString("autoOrganization", comment: "Auto organization feature title"), description: NSLocalizedString("automaticFoldersForEventsAndCategories", comment: "Auto organization description"))
                    GoogleDriveFeatureRow(icon: "iphone.and.arrow.forward", title: NSLocalizedString("accessAnywhere", comment: "Access anywhere feature title"), description: NSLocalizedString("viewDocumentsOnAnyDevice", comment: "Access anywhere description"))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Connection info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("afterConnection", comment: "After connection info title"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(NSLocalizedString("youllSeeYourGoogleAccountEmailInTheDocumentsView", comment: "Google account email info"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Auth button
                VStack(spacing: 12) {
                    Button(action: authenticateWithGoogleDrive) {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "icloud")
                            }
                            
                            Text(isAuthenticating ? NSLocalizedString("connecting", comment: "Connecting status") : NSLocalizedString("connectGoogleDrive", comment: "Connect Google Drive button"))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isAuthenticating)
                    
                    Button(NSLocalizedString("maybeLater", comment: "Maybe later button")) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle(NSLocalizedString("Google Drive", comment: "Google Drive navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("authenticationError", comment: "Authentication error alert title"), isPresented: .constant(authError != nil)) {
                Button(NSLocalizedString("OK", comment: "OK button")) {
                    authError = nil
                }
            } message: {
                Text(authError?.localizedDescription ?? NSLocalizedString("failedToConnectToGoogleDrive", comment: "Failed to connect error message"))
            }
        }
    }
    
    private func authenticateWithGoogleDrive() {
        isAuthenticating = true
        authError = nil
        
        googleDriveService.authenticate { result in
            DispatchQueue.main.async {
                isAuthenticating = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    authError = error
                }
            }
        }
    }
}

struct GoogleDriveFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    GoogleDriveAuthView()
}
