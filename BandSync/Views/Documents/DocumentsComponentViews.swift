//
//  DocumentsComponentViews.swift
//  BandSync
//
//  Created for Google Drive integration
//  Date: 16.06.2025
//

import SwiftUI

// MARK: - Supporting Views for Documents

struct EmptyDocumentsView: View {
    let hasSearchText: Bool
    let onCreateDocument: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(hasSearchText ? NSLocalizedString("noResultsFound", comment: "No search results found message") : NSLocalizedString("noDocumentsYet", comment: "No documents available message"))
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(hasSearchText ? NSLocalizedString("tryAdjustingYourSearchTerms", comment: "Search adjustment suggestion") : NSLocalizedString("createYourFirstDocumentToGetStarted", comment: "Create first document suggestion"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasSearchText {
                Button(action: onCreateDocument) {
                    Label(NSLocalizedString("createDocument", comment: "Create document button"), systemImage: "doc.badge.plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct DocumentsList: View {
    let documents: [Document]
    let onDelete: (Document) -> Void
    let onShare: (Document) -> Void
    let onOpenInGoogleDrive: (Document) -> Void
    let onDownload: (Document) -> Void
    
    var body: some View {
        List {
            ForEach(documents) { document in
                NavigationLink(destination: DocumentDetailView(document: document)) {
                    DocumentRowView(
                        document: document,
                        onDelete: { onDelete(document) },
                        onShare: { onShare(document) },
                        onOpenInGoogleDrive: { onOpenInGoogleDrive(document) },
                        onDownload: { onDownload(document) }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct DocumentRowView: View {
    let document: Document
    let onDelete: () -> Void
    let onShare: () -> Void
    let onOpenInGoogleDrive: () -> Void
    let onDownload: () -> Void
    
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationLink(destination: DocumentDetailView(document: document)) {
            HStack(spacing: 12) {
                // Document type icon
                Image(systemName: document.type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Document name
                    Text(document.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Document type and venue type
                    HStack(spacing: 8) {
                        Text(document.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if let venueType = document.venueType {
                            Text(venueType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Additional info
                    HStack(spacing: 16) {
                        if document.isTemplate {
                            Label(NSLocalizedString("Template", comment: "Document template label"), systemImage: "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        if document.isGoogleDriveDocument {
                            Label(NSLocalizedString("Drive", comment: "Google Drive document label"), systemImage: "icloud")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Text(document.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        // Отдельное меню для действий, чтобы не мешать навигации
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onShare()
            } label: {
                Label(NSLocalizedString("Share", comment: "Share document button"), systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
            
            if document.isGoogleDriveDocument {
                Button {
                    onOpenInGoogleDrive()
                } label: {
                    Label(NSLocalizedString("Drive", comment: "Open in Google Drive button"), systemImage: "arrow.up.right.square")
                }
                .tint(.green)
            }
        }
    }
    
    private func canEditDocument() -> Bool {
        guard let user = AppState.shared.user else { return false }
        return DocumentService.shared.canUserEdit(document, user: user)
    }
    
    private func canDeleteDocument() -> Bool {
        guard let user = AppState.shared.user else { return false }
        return DocumentService.shared.canUserDelete(document, user: user)
    }
}

struct GoogleDriveConnectionBanner: View {
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "icloud.slash")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("googleDriveNotConnected", comment: "Google Drive not connected message"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(NSLocalizedString("connectToUploadAndManageDocuments", comment: "Connect to upload documents message"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(NSLocalizedString("Connect", comment: "Connect to Google Drive button"), action: onConnect)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding()
        }
        .background(Color.orange.opacity(0.1))
    }
}

#Preview {
    EmptyDocumentsView(hasSearchText: false) {
        print("Create document tapped")
    }
}
