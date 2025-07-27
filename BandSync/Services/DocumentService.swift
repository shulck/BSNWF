//
//  DocumentService.swift
//  BandSync
//
//  Created for Google Drive document management only
//  Date: 16.06.2025
//

import Foundation
import Combine

final class DocumentService: ObservableObject {
    static let shared = DocumentService()
    
    @Published var documents: [Document] = []
    @Published var templates: [DocumentTemplate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let googleDriveService = GoogleDriveService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadDefaultTemplates()
        
        googleDriveService.$documents
            .receive(on: DispatchQueue.main)
            .assign(to: \.documents, on: self)
            .store(in: &cancellables)
            
        googleDriveService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    func loadDocuments() async {
        await googleDriveService.loadDocuments()
    }
    
    func refreshDocuments() async {
        await googleDriveService.refreshDocuments()
    }
    
    func uploadDocument(name: String, data: Data, type: DocumentType, completion: @escaping (Result<Document, Error>) -> Void) {
        googleDriveService.uploadDocument(name: name, data: data, type: type) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let document):
                    // Добавляем документ в локальный массив
                    self?.documents.append(document)
                    completion(.success(document))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func downloadDocument(_ document: Document, completion: @escaping (Result<Data, Error>) -> Void) {
        googleDriveService.downloadDocument(document, completion: completion)
    }
    
    func deleteDocument(_ document: Document, completion: @escaping (Result<Void, Error>) -> Void) {
        googleDriveService.deleteDocument(document: document) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Удаляем документ из локального массива
                    self?.documents.removeAll { $0.id == document.id }
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateDocument(_ document: Document, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    private func loadDefaultTemplates() {
        templates = [
            DocumentTemplate(
                name: "Basic Technical Rider",
                type: .technicalRider,
                description: "Basic technical requirements template",
                templateContent: "Technical Requirements:\n\n1. Sound System\n2. Lighting\n3. Stage Setup\n4. Power Requirements",
                createdBy: "system"
            ),
            DocumentTemplate(
                name: "Club Hospitality Rider",
                type: .hospitalityRider,
                venueType: .club,
                description: "Standard hospitality requirements for club venues",
                templateContent: "Hospitality Requirements:\n\n1. Catering\n2. Beverages\n3. Green Room\n4. Parking",
                createdBy: "system"
            )
        ]
    }
    
    func createDocumentFromTemplate(
        _ template: DocumentTemplate,
        name: String,
        completion: @escaping (Result<Document, Error>) -> Void
    ) {
        let content = template.templateContent ?? "Document created from template: \(template.name)"
        let data = content.data(using: .utf8) ?? Data()
        
        self.uploadDocument(name: name, data: data, type: template.type) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func createDocumentFromFileData(
        _ data: Data,
        name: String,
        type: DocumentType,
        completion: @escaping (Result<Document, Error>) -> Void
    ) {
        self.uploadDocument(name: name, data: data, type: type) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func canUserEdit(_ document: Document, user: UserModel) -> Bool {
        return true
    }
    
    func canUserDelete(_ document: Document, user: UserModel) -> Bool {
        return true
    }
}
