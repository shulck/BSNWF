//
//  CreateDocumentView.swift
//  BandSync
//
//  Created for Google Drive integration
//  Date: 16.06.2025
//

import SwiftUI
import PhotosUI

struct CreateDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var documentService = DocumentService.shared
    @StateObject private var googleDriveService = GoogleDriveService.shared
    
    @State private var documentName = ""
    @State private var documentDescription = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedFileData: Data? = nil
    @State private var selectedFileName = ""
    @State private var showingFilePicker = false
    @State private var isUploading = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                // Document Info Section
                Section(NSLocalizedString("documentInformation", comment: "Document Information")) {
                    TextField(NSLocalizedString("documentName", comment: "Document Name"), text: $documentName)
                        .textInputAutocapitalization(.words)
                    
                    TextField(NSLocalizedString("descriptionOptional", comment: "Description (Optional)"), text: $documentDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // File Upload Section
                Section(NSLocalizedString("fileUpload", comment: "File Upload")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Button {
                                    showingFilePicker = true
                                } label: {
                                    Label(NSLocalizedString("chooseFile", comment: "Choose File"), systemImage: "doc.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                PhotosPicker(
                                    selection: $selectedPhotoItem,
                                    matching: .images
                                ) {
                                    Label(NSLocalizedString("photo", comment: "Photo"), systemImage: "photo")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if !selectedFileName.isEmpty {
                                HStack {
                                    Image(systemName: "doc")
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text(selectedFileName)
                                            .font(.subheadline)
                                        
                                        if let data = selectedFileData {
                                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(NSLocalizedString("remove", comment: "Remove")) {
                                        selectedFileData = nil
                                        selectedFileName = ""
                                        selectedPhotoItem = nil
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                
                // Google Drive Status
                Section(NSLocalizedString("storage", comment: "Storage")) {
                    HStack {
                        Image(systemName: googleDriveService.isAuthenticated ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(googleDriveService.isAuthenticated ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text(NSLocalizedString("googleDrive", comment: "Google Drive"))
                                .font(.subheadline)
                            
                            Text(googleDriveService.isAuthenticated ? NSLocalizedString("connected", comment: "Connected") : NSLocalizedString("notConnected", comment: "Not Connected"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !googleDriveService.isAuthenticated {
                            Button(NSLocalizedString("connect", comment: "Connect")) {
                                connectToGoogleDrive()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("newDocument", comment: "New Document"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("create", comment: "Create")) {
                        createDocument()
                    }
                    .disabled(!isFormValid || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    uploadingOverlay
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .text, .image], // Убрали .data чтобы исключить аудио/видео
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem)
            }
            .alert(NSLocalizedString("error", comment: "Error"), isPresented: $showingError) {
                Button(NSLocalizedString("ok", comment: "OK")) { }
            } message: {
                Text(errorMessage ?? NSLocalizedString("unknownErrorOccurred", comment: "Unknown error occurred"))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        let hasValidName = !documentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isAuthenticated = googleDriveService.isAuthenticated
        let hasValidContent = selectedFileData != nil
        
        return hasValidName && isAuthenticated && hasValidContent
    }
    
    private var uploadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(NSLocalizedString("creatingDocument", comment: "Creating Document"))
                .font(.headline)
            
            Text(NSLocalizedString("uploadingToGoogleDrive", comment: "Uploading to Google Drive"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    // MARK: - Actions
    
    private func createDocument() {
        guard isFormValid else { return }
        
        isUploading = true
        errorMessage = nil
        
        if let fileData = selectedFileData {
            uploadFile(fileData)
        }
    }
    
    private func uploadFile(_ data: Data) {
        documentService.createDocumentFromFileData(
            data,
            name: documentName.isEmpty ? selectedFileName : documentName,
            type: .other  // Просто используем .other для всех файлов
        ) { result in
            self.isUploading = false
            
            switch result {
            case .success:
                self.dismiss()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
    }
    
    private func connectToGoogleDrive() {
        googleDriveService.authenticate { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Authentication successful
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                return
            }
            
            // Проверяем тип файла перед загрузкой
            let fileName = url.lastPathComponent.lowercased()
            if isAudioOrVideoFile(fileName) {
                self.errorMessage = NSLocalizedString("audioVideoFilesNotSupported", comment: "Audio and video files upload is not supported from the app. Please use Google Drive web interface to upload such files.")
                self.showingError = true
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                self.errorMessage = NSLocalizedString("failedToAccessFile", comment: "Failed to access selected file") + ": " + NSLocalizedString("permissionDenied", comment: "Permission denied")
                self.showingError = true
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let data = try Data(contentsOf: url)
                
                // Дополнительная проверка по содержимому файла
                if isAudioOrVideoData(data) {
                    self.errorMessage = NSLocalizedString("audioVideoFilesNotSupported", comment: "Audio and video files upload is not supported from the app. Please use Google Drive web interface to upload such files.")
                    self.showingError = true
                    return
                }
                
                self.selectedFileData = data
                self.selectedFileName = url.lastPathComponent
            } catch {
                self.errorMessage = NSLocalizedString("failedToReadFile", comment: "Failed to read selected file") + ": \(error.localizedDescription)"
                self.showingError = true
            }
            
        case .failure(let error):
            self.errorMessage = NSLocalizedString("failedToSelectFile", comment: "Failed to select file") + ": \(error.localizedDescription)"
            self.showingError = true
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data {
                        self.selectedFileData = data
                        self.selectedFileName = "photo.jpg"
                    }
                case .failure(let error):
                    self.errorMessage = NSLocalizedString("failedToLoadPhoto", comment: "Failed to load photo") + ": \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    // MARK: - File Type Validation
    
    private func isAudioOrVideoFile(_ fileName: String) -> Bool {
        let audioExtensions = [".mp3", ".wav", ".m4a", ".aac", ".flac", ".ogg", ".wma"]
        let videoExtensions = [".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".webm", ".m4v"]
        
        for ext in audioExtensions + videoExtensions {
            if fileName.hasSuffix(ext) {
                return true
            }
        }
        return false
    }
    
    private func isAudioOrVideoData(_ data: Data) -> Bool {
        // Проверяем заголовки аудио файлов
        let mp3Header = Data([0xFF, 0xFB]) // MP3
        let mp3Header2 = Data([0xFF, 0xFA]) // MP3
        let mp3ID3 = Data([0x49, 0x44, 0x33]) // ID3
        let wavHeader = Data([0x52, 0x49, 0x46, 0x46]) // RIFF (WAV)
        let m4aHeader = Data([0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41]) // M4A
        
        // Проверяем заголовки видео файлов
        let mp4Header = Data([0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70]) // MP4
        let mp4Header2 = Data([0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70]) // MP4
        let movHeader = Data([0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74]) // MOV
        let aviHeader = Data([0x52, 0x49, 0x46, 0x46]) // AVI (тоже RIFF)
        
        return data.starts(with: mp3Header) ||
               data.starts(with: mp3Header2) ||
               data.starts(with: mp3ID3) ||
               data.starts(with: wavHeader) ||
               data.starts(with: m4aHeader) ||
               data.starts(with: mp4Header) ||
               data.starts(with: mp4Header2) ||
               data.starts(with: movHeader) ||
               data.starts(with: aviHeader)
    }
}

#Preview {
    CreateDocumentView()
}
