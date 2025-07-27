//
//  DocumentDetailView.swift
//  BandSync
//
//  Created for Google Drive integration
//  Date: 16.06.2025
//

import SwiftUI
import PDFKit
import AVFoundation

struct DocumentDetailView: View {
    let document: Document
    @StateObject private var documentService = DocumentService.shared
    @StateObject private var googleDriveService = GoogleDriveService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var documentData: Data? = nil
    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Document preview
            if isLoading {
                loadingView
            } else if let data = documentData {
                documentPreview(data: data)
            } else {
                documentInfoView
            }
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if document.isGoogleDriveDocument {
                        Button {
                            openInGoogleDrive()
                        } label: {
                            Label("Open in Google Drive".localized, systemImage: "arrow.up.right.square")
                        }
                        
                        Button {
                            downloadDocument()
                        } label: {
                            Label("Download Preview".localized, systemImage: "arrow.down.circle")
                        }
                    }
                    
                    Button {
                        shareDocument()
                    } label: {
                        Label("Share".localized, systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Info".localized, systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        })
        .onAppear {
            if document.isGoogleDriveDocument && documentData == nil {
                downloadDocument()
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDocumentView(document: document)
        }
        .alert("Error".localized, isPresented: $showingError) {
            Button("OK".localized) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred".localized)
        }
        .alert("Delete Document".localized, isPresented: $showingDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("Are you sure you want to delete this document?".localized.replacingOccurrences(of: "{name}", with: document.name))
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading Document".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var documentInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Document")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let description = document.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Document properties
                VStack(alignment: .leading, spacing: 16) {
                    Text("Properties".localized)
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        PropertyRow(
                            title: "Created".localized,
                            value: formatDate(document.createdAt),
                            icon: "calendar"
                        )
                        
                        PropertyRow(
                            title: "Updated".localized,
                            value: formatDate(document.updatedAt),
                            icon: "clock"
                        )
                        
                        if document.fileSize != nil {
                            PropertyRow(
                                title: "Size".localized,
                                value: document.formattedFileSize,
                                icon: "doc"
                            )
                        }
                        
                        if document.isGoogleDriveDocument {
                            PropertyRow(
                                title: "Storage".localized,
                                value: "Google Drive".localized,
                                icon: "icloud"
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Actions
                VStack(spacing: 12) {
                    if document.isGoogleDriveDocument {
                        Button {
                            openInGoogleDrive()
                        } label: {
                            Label("Open in Google Drive".localized, systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            downloadDocument()
                        } label: {
                            Label("Download Preview".localized, systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button {
                        shareDocument()
                    } label: {
                        Label("Share Document".localized, systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func documentPreview(data: Data) -> some View {
        Group {
            // Исправленная логика определения типа файла
            if isPDFFile(data: data) || document.mimeType.contains("pdf") {
                PDFPreviewView(data: data)
            } else if isImageFile(data: data) || isImageMimeType(document.mimeType) {
                ImagePreviewView(data: data)
            } else if isAudioFile() || isAudioMimeType(document.mimeType) {
                AudioPreviewView(data: data, fileName: document.name)
            } else if isVideoFile() || isVideoMimeType(document.mimeType) {
                UnsupportedFileTypeView(fileType: "Video", fileName: document.name)
            } else if isTextFile(data: data) || document.mimeType.contains("text") {
                TextPreviewView(data: data)
            } else {
                // Fallback для неизвестных типов файлов
                UnknownFilePreviewView(document: document, data: data)
            }
        }
    }
    
    // MARK: - File Type Detection Helpers
    
    private func isPDFFile(data: Data) -> Bool {
        // PDF файлы начинаются с "%PDF"
        let pdfHeader = Data([0x25, 0x50, 0x44, 0x46]) // %PDF
        return data.starts(with: pdfHeader)
    }
    
    private func isImageFile(data: Data) -> Bool {
        // Проверяем заголовки различных форматов изображений
        let jpegHeader1 = Data([0xFF, 0xD8, 0xFF])
        let jpegHeader2 = Data([0xFF, 0xD8])
        let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let gifHeader = Data([0x47, 0x49, 0x46])
        let heicHeader = Data([0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70])
        
        return data.starts(with: jpegHeader1) ||
               data.starts(with: jpegHeader2) ||
               data.starts(with: pngHeader) ||
               data.starts(with: gifHeader) ||
               data.contains(heicHeader)
    }
    
    private func isAudioFile() -> Bool {
        let fileName = document.name.lowercased()
        return fileName.hasSuffix(".mp3") ||
               fileName.hasSuffix(".wav") ||
               fileName.hasSuffix(".m4a") ||
               fileName.hasSuffix(".aac") ||
               fileName.hasSuffix(".flac")
    }
    
    private func isVideoFile() -> Bool {
        let fileName = document.name.lowercased()
        return fileName.hasSuffix(".mp4") ||
               fileName.hasSuffix(".mov") ||
               fileName.hasSuffix(".avi") ||
               fileName.hasSuffix(".mkv") ||
               fileName.hasSuffix(".wmv") ||
               fileName.hasSuffix(".flv") ||
               fileName.hasSuffix(".webm") ||
               fileName.hasSuffix(".m4v")
    }
    
    private func isTextFile(data: Data) -> Bool {
        // Простая проверка на текстовый файл
        guard let string = String(data: data.prefix(1024), encoding: .utf8) else {
            return false
        }
        // Если можем декодировать как UTF-8 и содержит печатные символы
        return !string.isEmpty && string.unicodeScalars.allSatisfy {
            CharacterSet.whitespacesAndNewlines.contains($0) ||
            CharacterSet.alphanumerics.contains($0) ||
            CharacterSet.punctuationCharacters.contains($0) ||
            CharacterSet.symbols.contains($0)
        }
    }
    
    private func isImageMimeType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("image/")
    }
    
    private func isAudioMimeType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("audio/")
    }
    
    private func isVideoMimeType(_ mimeType: String) -> Bool {
        return mimeType.hasPrefix("video/")
    }
    
    // MARK: - Computed Properties
    
    private var canEditDocument: Bool {
        guard let user = AppState.shared.user else { return false }
        return documentService.canUserEdit(document, user: user)
    }
    
    private var canDeleteDocument: Bool {
        guard let user = AppState.shared.user else { return false }
        return documentService.canUserDelete(document, user: user)
    }
    
    // MARK: - Actions
    
    private func downloadDocument() {
        guard document.isGoogleDriveDocument else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        googleDriveService.downloadDocument(document: document) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    print("✅ Downloaded file: \(data.count) bytes")
                    print("📄 MIME type: \(self.document.mimeType)")
                    print("📁 File name: \(self.document.name)")
                    self.documentData = data
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to download document".localized + ": \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func openInGoogleDrive() {
        guard let urlString = document.googleDriveUrl,
              let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
    
    private func deleteDocument() {
        guard !isDeleting else { return }
        
        isDeleting = true
        
        documentService.deleteDocument(document) { result in
            DispatchQueue.main.async {
                isDeleting = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    print("❌ Delete document error: \(error.localizedDescription)")
                    errorMessage = "Failed to delete document".localized + ": \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func shareDocument() {
        var itemsToShare: [Any] = []
        
        itemsToShare.append(document.name)
        
        if let urlString = document.googleDriveUrl,
           let url = URL(string: urlString) {
            itemsToShare.append(url)
        }
        
        if let description = document.description, !description.isEmpty {
            itemsToShare.append(description)
        }
        
        if let data = documentData {
            itemsToShare.append(data)
        }
        
        if itemsToShare.isEmpty {
            errorMessage = "No shareable content available for this document".localized
            showingError = true
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            errorMessage = "Unable to present share sheet".localized
            showingError = true
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                      y: rootViewController.view.bounds.midY,
                                      width: 0,
                                      height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct PropertyRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ImagePreviewView: View {
    let data: Data
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        if let uiImage = UIImage(data: data) {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(0.5, min(value, 5.0)) // Ограничиваем масштаб
                                }
                                .onEnded { _ in
                                    if scale < 1.0 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = value.translation
                                    }
                                }
                                .onEnded { _ in
                                    // Возвращаем изображение в границы при необходимости
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        let maxOffsetX = max(0, (geometry.size.width * scale - geometry.size.width) / 2)
                                        let newOffsetX = max(-maxOffsetX, min(maxOffsetX, offset.width))
                                        
                                        let maxOffsetY = max(0, (geometry.size.height * scale - geometry.size.height) / 2)
                                        let newOffsetY = max(-maxOffsetY, min(maxOffsetY, offset.height))
                                        
                                        offset = CGSize(width: newOffsetX, height: newOffsetY)
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scale = scale > 1.0 ? 1.0 : 2.0
                                offset = .zero
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "photo")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Unable to display image")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("The file may be corrupted or in an unsupported format")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Показываем информацию о файле для отладки
                VStack(spacing: 8) {
                    Text("File size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    if data.count > 0 {
                        Text("First 16 bytes: \(data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " "))")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

struct TextPreviewView: View {
    let data: Data
    
    var body: some View {
        ScrollView {
            if let text = String(data: data, encoding: .utf8) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let text = String(data: data, encoding: .ascii) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Unable to display text content")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("File encoding is not supported for preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
}

struct AudioPreviewView: View {
    let data: Data
    let fileName: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Иконка аудио файла
            Image(systemName: "music.note")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text(fileName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("Audio File")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Информация о файле
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "doc")
                        .foregroundColor(.blue)
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                        .font(.subheadline)
                }
                
                // Определяем тип аудио файла
                let audioType = getAudioType(from: fileName)
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                    Text("Format: \(audioType)")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Информационное сообщение
            VStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Audio playback not supported in preview")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                
                Text("Use 'Open in Google Drive' to play the file")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func getAudioType(from fileName: String) -> String {
        let lowercased = fileName.lowercased()
        if lowercased.hasSuffix(".mp3") {
            return "MP3"
        } else if lowercased.hasSuffix(".wav") {
            return "WAV"
        } else if lowercased.hasSuffix(".m4a") {
            return "M4A"
        } else if lowercased.hasSuffix(".aac") {
            return "AAC"
        } else if lowercased.hasSuffix(".flac") {
            return "FLAC"
        } else {
            return "Audio"
        }
    }
}

struct UnsupportedFileTypeView: View {
    let fileType: String
    let fileName: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Иконка предупреждения
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 100))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text(fileName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("\(fileType) File")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Сообщение об ошибке
            VStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                    .font(.title3)
                
                Text("\(fileType) files are not supported in the app")
                    .font(.callout)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                Text("Use 'Open in Google Drive' to view this file")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct UnknownFilePreviewView: View {
    let document: Document
    let data: Data
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "doc")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text(document.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("Document")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Информация о файле
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.green)
                    Text("Type: \(document.mimeType)")
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Информационное сообщение
            VStack(spacing: 8) {
                Image(systemName: "eye.slash")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Preview not available for this file type")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                
                Text("Use 'Open in Google Drive' to view the file")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct PDFViewerRepresented: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}

struct EditDocumentView: View {
    let document: Document
    @Environment(\.dismiss) private var dismiss
    @StateObject private var documentService = DocumentService.shared
    
    @State private var name: String
    @State private var description: String
    @State private var venueType: VenueType?
    @State private var isUpdating = false
    
    init(document: Document) {
        self.document = document
        self._name = State(initialValue: document.name)
        self._description = State(initialValue: document.description ?? "")
        self._venueType = State(initialValue: document.venueType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Document Information".localized) {
                    TextField("Name".localized, text: $name)
                    TextField("Description".localized, text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Document".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save".localized) {
                        updateDocument()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdating)
                }
            }
            .overlay {
                if isUpdating {
                    ProgressView("Updating".localized)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                }
            }
        }
    }
    
    private func updateDocument() {
        isUpdating = true
        
        var updatedDocument = document
        updatedDocument.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedDocument.description = description.isEmpty ? nil : description
        
        documentService.updateDocument(updatedDocument) { result in
            DispatchQueue.main.async {
                isUpdating = false
                switch result {
                case .success:
                    dismiss()
                case .failure:
                    break
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DocumentDetailView(document: Document(
            name: "Technical Rider - Club",
            type: .technicalRider,
            venueType: .club,
            description: "Standard technical rider for club performances",
            mimeType: "application/pdf",
            groupId: "test-group",
            createdBy: "test-user"
        ))
    }
}
