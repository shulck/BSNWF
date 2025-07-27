import Foundation
import Combine
import UIKit

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var searchText: String = ""
    @Published var isGoogleDriveConnected: Bool = false
    @Published var selectedCategory: DocumentType?
    @Published var selectedFolder: String?
    
    private let documentService = DocumentService.shared
    private let googleDriveService = GoogleDriveService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        documentService.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
        
        documentService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        googleDriveService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isGoogleDriveConnected, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func loadDocuments() async {
        await documentService.loadDocuments()
    }
    
    func refreshDocuments() async {
        await documentService.refreshDocuments()
    }
    
    func checkGoogleDriveConnection() async {
        // Google Drive connection status is handled automatically via bindings
    }
    
    func deleteDocument(_ document: Document) {
        documentService.deleteDocument(document) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    
    func shareDocument(_ document: Document) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("No root view controller found for sharing")
            return
        }
        
        var itemsToShare: [Any] = []
        
        itemsToShare.append(document.name)
        
        if let urlString = document.googleDriveUrl,
           let url = URL(string: urlString) {
            itemsToShare.append(url)
        }
        
        if let description = document.description, !description.isEmpty {
            itemsToShare.append(description)
        }
        
        if itemsToShare.isEmpty {
            print("No shareable content found for document: \(document.name)")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: [UIActivity]?.none
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
    
    func openInGoogleDrive(_ document: Document) {
        if let googleDriveFileId = document.googleDriveFileId {
            if let url = URL(string: "https://drive.google.com/file/d/\(googleDriveFileId)/view") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func downloadDocument(_ document: Document) {
        documentService.downloadDocument(document) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("Document downloaded: \(data.count) bytes")
                case .failure(let error):
                    print("Error downloading document: \(error)")
                    self.error = error
                }
            }
        }
    }
    
    func disconnectGoogleDrive() {
        googleDriveService.disconnect()
    }
}
