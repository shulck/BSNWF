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
                Section("Document Information".localized) {
                    TextField("Document Name".localized, text: $documentName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (Optional)".localized, text: $documentDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // File Upload Section
                Section("File Upload".localized) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Button {
                                    showingFilePicker = true
                                } label: {
                                    Label("Choose File".localized, systemImage: "doc.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                PhotosPicker(
                                    selection: $selectedPhotoItem,
                                    matching: .images
                                ) {
                                    Label("Photo".localized, systemImage: "photo")
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
                                    
                                    Button("Remove".localized) {
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
                Section("Storage".localized) {
                    HStack {
                        Image(systemName: googleDriveService.isAuthenticated ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(googleDriveService.isAuthenticated ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text("Google Drive".localized)
                                .font(.subheadline)
                            
                            Text(googleDriveService.isAuthenticated ? "Connected".localized : "Not Connected".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !googleDriveService.isAuthenticated {
                            Button("Connect".localized) {
                                connectToGoogleDrive()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("New Document".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create".localized) {
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
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred".localized)
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
            
            Text("Creating Document".localized)
                .font(.headline)
            
            Text("Uploading to Google Drive".localized)
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
                self.errorMessage = "Audio and video files upload is not supported from the app. Please use Google Drive web interface to upload such files.".localized
                self.showingError = true
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                self.errorMessage = "Failed to access selected file".localized + ": " + "Permission denied".localized
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
                    self.errorMessage = "Audio and video files upload is not supported from the app. Please use Google Drive web interface to upload such files.".localized
                    self.showingError = true
                    return
                }
                
                self.selectedFileData = data
                self.selectedFileName = url.lastPathComponent
            } catch {
                self.errorMessage = "Failed to read selected file".localized + ": \(error.localizedDescription)"
                self.showingError = true
            }
            
        case .failure(let error):
            self.errorMessage = "Failed to select file".localized + ": \(error.localizedDescription)"
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
                    self.errorMessage = "Failed to load photo".localized + ": \(error.localizedDescription)"
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
