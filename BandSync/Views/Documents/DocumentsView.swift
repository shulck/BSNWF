//
//  DocumentsView.swift
//  BandSync
//
//  Created for Google Drive integration
//  Date: 16.06.2025
//

import SwiftUI

struct DocumentsView: View {
    @StateObject private var viewModel = DocumentsViewModel()
    @State private var selectedDocumentType: DocumentType? = nil
    @State private var showingCreateDocument = false
    @State private var showingGoogleDriveAuth = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Google Drive connection status
            if !viewModel.isGoogleDriveConnected {
                googleDriveConnectionBanner
            } else {
                googleDriveConnectedBanner
            }
            
            // Main content
            if viewModel.isLoading && viewModel.documents.isEmpty {
                loadingView
            } else if filteredDocuments.isEmpty {
                emptyStateView
            } else {
                documentListView
            }
        }
        .navigationTitle(NSLocalizedString("Documents", comment: "Documents screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if viewModel.isGoogleDriveConnected {
                        Button {
                            showingCreateDocument = true
                        } label: {
                            Label(NSLocalizedString("New Document", comment: "New document button"), systemImage: "doc.badge.plus")
                        }
                        
                        Divider()
                        
                        Button {
                            Task {
                                await viewModel.refreshDocuments()
                            }
                        } label: {
                            Label(NSLocalizedString("Refresh", comment: "Refresh documents button"), systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            disconnectGoogleDrive()
                        } label: {
                            Label(NSLocalizedString("Disconnect Google Drive", comment: "Disconnect Google Drive button"), systemImage: "icloud.slash")
                        }
                        .foregroundColor(.red)
                    } else {
                        Button {
                            showingGoogleDriveAuth = true
                        } label: {
                            Label(NSLocalizedString("Connect Google Drive", comment: "Connect Google Drive button"), systemImage: "icloud")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.refreshDocuments()
        }
        .sheet(isPresented: $showingCreateDocument) {
            CreateDocumentView()
        }
        .sheet(isPresented: $showingGoogleDriveAuth) {
            GoogleDriveAuthView()
        }
        .onAppear {
            Task {
                await viewModel.loadDocuments()
                await viewModel.checkGoogleDriveConnection()
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
    }
    
    // MARK: - Views
    
    private var googleDriveConnectionBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "icloud.slash")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("Google Drive Not Connected", comment: "Google Drive not connected banner title"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(NSLocalizedString("Connect to upload and manage documents", comment: "Google Drive connection description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(NSLocalizedString("Connect", comment: "Connect button")) {
                    showingGoogleDriveAuth = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
        }
        .background(Color.orange.opacity(0.1))
    }
    
    private var googleDriveConnectedBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("Google Drive Connected", comment: "Google Drive connected banner title"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(NSLocalizedString("Ready to upload and manage documents", comment: "Google Drive ready description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(NSLocalizedString("Disconnect", comment: "Disconnect button")) {
                    disconnectGoogleDrive()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
            .padding()
        }
        .background(Color.green.opacity(0.1))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(NSLocalizedString("Loading Documents", comment: "Loading documents message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "folder" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? NSLocalizedString("No Documents Yet", comment: "No documents message") : NSLocalizedString("No Results Found", comment: "No search results message"))
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(searchText.isEmpty ? NSLocalizedString("Create your first document to get started", comment: "Create first document suggestion") : NSLocalizedString("Try adjusting your search terms", comment: "Search adjustment suggestion"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                if viewModel.isGoogleDriveConnected {
                    Button {
                        showingCreateDocument = true
                    } label: {
                        Label(NSLocalizedString("Create Document", comment: "Create document button"), systemImage: "doc.badge.plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button {
                        showingGoogleDriveAuth = true
                    } label: {
                        Label(NSLocalizedString("Connect Google Drive", comment: "Connect Google Drive button"), systemImage: "icloud")
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var documentListView: some View {
        List {
            // Document type filter chips
            if !viewModel.documents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: NSLocalizedString("All", comment: "All documents filter"),
                            isSelected: selectedDocumentType == nil,
                            count: viewModel.documents.count
                        ) {
                            selectedDocumentType = nil
                        }
                        
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            let count = viewModel.documents.filter { $0.type == type }.count
                            if count > 0 {
                                FilterChip(
                                    title: type.displayName,
                                    isSelected: selectedDocumentType == type,
                                    count: count
                                ) {
                                    selectedDocumentType = selectedDocumentType == type ? nil : type
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // Documents
            ForEach(filteredDocuments) { document in
                DocumentRowView(
                    document: document,
                    onDelete: { viewModel.deleteDocument(document) },
                    onShare: { viewModel.shareDocument(document) },
                    onOpenInGoogleDrive: { viewModel.openInGoogleDrive(document) },
                    onDownload: { viewModel.downloadDocument(document) }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Computed Properties
    
    private var filteredDocuments: [Document] {
        var documents = viewModel.documents
        
        // Filter by type
        if let selectedType = selectedDocumentType {
            documents = documents.filter { $0.type == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            documents = documents.filter { document in
                document.name.localizedCaseInsensitiveContains(searchText) ||
                document.type.displayName.localizedCaseInsensitiveContains(searchText) ||
                (document.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return documents
    }
    
    // MARK: - Actions
    
    private func disconnectGoogleDrive() {
        viewModel.disconnectGoogleDrive()
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var count: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let count = count {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DocumentsView()
}
