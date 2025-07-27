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
        .navigationTitle("Documents".localized)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if viewModel.isGoogleDriveConnected {
                        Button {
                            showingCreateDocument = true
                        } label: {
                            Label("New Document".localized, systemImage: "doc.badge.plus")
                        }
                        
                        Divider()
                        
                        Button {
                            Task {
                                await viewModel.refreshDocuments()
                            }
                        } label: {
                            Label("Refresh".localized, systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            disconnectGoogleDrive()
                        } label: {
                            Label("Disconnect Google Drive".localized, systemImage: "icloud.slash")
                        }
                        .foregroundColor(.red)
                    } else {
                        Button {
                            showingGoogleDriveAuth = true
                        } label: {
                            Label("Connect Google Drive".localized, systemImage: "icloud")
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
                    Text("Google Drive Not Connected".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Connect to upload and manage documents".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Connect".localized) {
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
                    Text("Google Drive Connected".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Ready to upload and manage documents".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Disconnect".localized) {
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
            
            Text("Loading Documents".localized)
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
                Text(searchText.isEmpty ? "No Documents Yet".localized : "No Results Found".localized)
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(searchText.isEmpty ? "Create your first document to get started".localized : "Try adjusting your search terms".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                if viewModel.isGoogleDriveConnected {
                    Button {
                        showingCreateDocument = true
                    } label: {
                        Label("Create Document".localized, systemImage: "doc.badge.plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button {
                        showingGoogleDriveAuth = true
                    } label: {
                        Label("Connect Google Drive".localized, systemImage: "icloud")
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
                            title: "All".localized,
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
