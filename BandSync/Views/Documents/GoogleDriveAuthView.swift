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
                        Text("connectGoogleDrive".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("connectYourGoogleDriveAccountToSecurelyStore".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    GoogleDriveFeatureRow(icon: "lock.shield", title: "secureStorage".localized, description: "yourDocumentsAreEncryptedAndSafelyStored".localized)
                    GoogleDriveFeatureRow(icon: "person.2", title: "teamCollaboration".localized, description: "shareDocumentsWithBandMembers".localized)
                    GoogleDriveFeatureRow(icon: "folder.badge.plus", title: "autoOrganization".localized, description: "automaticFoldersForEventsAndCategories".localized)
                    GoogleDriveFeatureRow(icon: "iphone.and.arrow.forward", title: "accessAnywhere".localized, description: "viewDocumentsOnAnyDevice".localized)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Connection info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("afterConnection".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("youllSeeYourGoogleAccountEmailInTheDocumentsView".localized)
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
                            
                            Text(isAuthenticating ? "connecting".localized : "connectGoogleDrive".localized)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isAuthenticating)
                    
                    Button("maybeLater".localized) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Google Drive".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("authenticationError".localized, isPresented: .constant(authError != nil)) {
                Button("OK".localized) {
                    authError = nil
                }
            } message: {
                Text(authError?.localizedDescription ?? "failedToConnectToGoogleDrive".localized)
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
