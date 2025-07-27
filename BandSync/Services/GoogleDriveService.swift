//
//  GoogleDriveService.swift
//  BandSync
//
//  Google Drive integration with real SDK implementation
//  Date: 16.06.2025
//

import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST_Drive

protocol GoogleDriveServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUserEmail: String? { get }
    
    func authenticate(completion: @escaping (Result<Void, GoogleDriveError>) -> Void)
    func uploadDocument(data: Data, name: String, type: DocumentType, completion: @escaping (Result<Document, GoogleDriveError>) -> Void)
    func downloadDocument(document: Document, completion: @escaping (Result<Data, GoogleDriveError>) -> Void)
    func listDocuments(completion: @escaping (Result<[Document], GoogleDriveError>) -> Void)
    func createFolder(name: String, completion: @escaping (Result<DocumentFolder, GoogleDriveError>) -> Void)
    func deleteDocument(document: Document, completion: @escaping (Result<Void, GoogleDriveError>) -> Void)
    func disconnect()
    func checkAuthenticationStatus() -> Bool
}

enum GoogleDriveError: Error {
    case authenticationFailed
    case noViewController
    case networkError(Error)
    case fileNotFound
    case uploadFailed
    case downloadFailed
    case invalidData
    case notAuthenticated
    case invalidFileId
    
    var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            return "Authentication failed"
        case .noViewController:
            return "No view controller available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileNotFound:
            return "File not found"
        case .uploadFailed:
            return "Upload failed"
        case .downloadFailed:
            return "Download failed"
        case .invalidData:
            return "Invalid data"
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidFileId:
            return "Invalid file ID"
        }
    }
}

class GoogleDriveService: ObservableObject, GoogleDriveServiceProtocol {
    static let shared = GoogleDriveService()
    
    @Published var isAuthenticated = false
    @Published var currentUserEmail: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var documents: [Document] = []
    
    private let driveService = GTLRDriveService()
    private let cacheService = CacheService.shared
    private let scopes = [kGTLRAuthScopeDriveFile]
    private var authRefreshInProgress = false
    private var lastAuthCheck: Date?
    
    var userEmail: String? { return currentUserEmail }
    var userName: String? { return currentUserEmail?.components(separatedBy: "@").first }
    
    private init() {
        setupDriveService()
        performInitialAuthCheck()
    }
    
    private func performInitialAuthCheck() {
        guard !authRefreshInProgress else { return }
        
        let now = Date()
        if let lastCheck = lastAuthCheck, now.timeIntervalSince(lastCheck) < 30 {
            return
        }
        
        lastAuthCheck = now
        authRefreshInProgress = true
        
        let _ = UserDefaults.standard.bool(forKey: "GoogleDriveAuthenticated")
        let _ = UserDefaults.standard.string(forKey: "GoogleDriveUserEmail")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.checkAndUpdateAuthStatus()
        }
    }
    
    private func checkAndUpdateAuthStatus() {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            handleNoCurrentUser()
            return
        }
        
        if let expirationDate = user.accessToken.expirationDate, expirationDate <= Date() {
            refreshTokenIfNeeded(user: user)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateAuthenticatedState(user: user)
                self?.authRefreshInProgress = false
            }
        }
    }
    
    private func handleNoCurrentUser() {
        let wasAuthenticated = UserDefaults.standard.bool(forKey: "GoogleDriveAuthenticated")
        let savedEmail = UserDefaults.standard.string(forKey: "GoogleDriveUserEmail")
        
        if wasAuthenticated && savedEmail != nil {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                if error != nil {
                    DispatchQueue.main.async {
                        self?.isAuthenticated = false
                        self?.currentUserEmail = nil
                        self?.authRefreshInProgress = false
                    }
                } else if let user = user {
                    DispatchQueue.main.async {
                        self?.updateAuthenticatedState(user: user)
                        self?.authRefreshInProgress = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.isAuthenticated = false
                        self?.currentUserEmail = nil
                        self?.authRefreshInProgress = false
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isAuthenticated = false
                self?.currentUserEmail = nil
                self?.authRefreshInProgress = false
            }
        }
    }
    
    func updateAuthenticatedState(user: GIDGoogleUser) {
        isAuthenticated = true
        currentUserEmail = user.profile?.email
        setupDriveService()
        
        UserDefaults.standard.set(true, forKey: "GoogleDriveAuthenticated")
        UserDefaults.standard.set(user.profile?.email, forKey: "GoogleDriveUserEmail")
    }
    
    func refreshAuthenticationStatus() {
        guard !authRefreshInProgress else { return }
        performInitialAuthCheck()
    }
    
    private func setupDriveService() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            driveService.authorizer = user.fetcherAuthorizer
        }
    }
    
    internal func checkAuthenticationStatus() -> Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            let wasAuthenticated = UserDefaults.standard.bool(forKey: "GoogleDriveAuthenticated")
            let savedEmail = UserDefaults.standard.string(forKey: "GoogleDriveUserEmail")
            
            if wasAuthenticated && savedEmail != nil {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user = user, error == nil {
                            DispatchQueue.main.async {
                                self?.updateAuthenticatedState(user: user)
                            }
                        }
                    }
                }
            }
            
            return false
        }
        
        if let expirationDate = user.accessToken.expirationDate, expirationDate <= Date() {
            refreshTokenIfNeeded(user: user)
            return false
        }
        
        self.currentUserEmail = user.profile?.email
        return true
    }
    
    private func refreshTokenIfNeeded(user: GIDGoogleUser) {
        user.refreshTokensIfNeeded { [weak self] result, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.isAuthenticated = false
                    self?.currentUserEmail = nil
                } else {
                    self?.updateAuthenticatedState(user: user)
                }
                self?.authRefreshInProgress = false
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    func authenticate(completion: @escaping (Result<Void, GoogleDriveError>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let presentingViewController = getRootViewController() else {
            isLoading = false
            completion(.failure(GoogleDriveError.noViewController))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let user = result?.user else {
                    completion(.failure(GoogleDriveError.authenticationFailed))
                    return
                }
                
                guard user.grantedScopes?.contains("https://www.googleapis.com/auth/drive.file") == true else {
                    self?.requestDriveScope(for: user, completion: completion)
                    return
                }
                
                self?.setupAuthenticatedUser(user)
                completion(.success(()))
            }
        }
    }
    
    private func requestDriveScope(for user: GIDGoogleUser, completion: @escaping (Result<Void, GoogleDriveError>) -> Void) {
        guard let presentingViewController = getRootViewController() else {
            completion(.failure(GoogleDriveError.noViewController))
            return
        }
        
        user.addScopes(scopes, presenting: presentingViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let user = result?.user else {
                    completion(.failure(GoogleDriveError.authenticationFailed))
                    return
                }
                
                self?.setupAuthenticatedUser(user)
                completion(.success(()))
            }
        }
    }
    
    private func setupAuthenticatedUser(_ user: GIDGoogleUser) {
        DispatchQueue.main.async {
            self.updateAuthenticatedState(user: user)
        }
    }
    
    func uploadDocument(data: Data, name: String, type: DocumentType, completion: @escaping (Result<Document, GoogleDriveError>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(GoogleDriveError.notAuthenticated))
            return
        }
        
        let file = GTLRDrive_File()
        file.name = name
        
        let uploadParameters = GTLRUploadParameters(data: data, mimeType: mimeType(for: type, fileName: name))
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
        driveService.executeQuery(query) { [weak self] (ticket, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(GoogleDriveError.uploadFailed))
                    return
                }
                
                guard let driveFile = result as? GTLRDrive_File,
                      let fileId = driveFile.identifier else {
                    completion(.failure(GoogleDriveError.uploadFailed))
                    return
                }
                
                let currentUserId = AppState.shared.user?.id ?? "unknown"
                let currentGroupId = AppState.shared.user?.groupId ?? "unknown"
                
                let document = Document(
                    id: UUID().uuidString,
                    name: name,
                    type: type,
                    venueType: nil,
                    description: nil,
                    googleDriveFileId: fileId,
                    googleDriveUrl: "https://drive.google.com/file/d/\(fileId)/view",
                    mimeType: self?.mimeType(for: type, fileName: name) ?? "application/octet-stream",
                    groupId: currentGroupId,
                    createdBy: currentUserId,
                    createdAt: Date(),
                    updatedAt: Date(),
                    version: 1,
                    eventId: nil,
                    folderId: nil,
                    isTemplate: false,
                    isPublic: false
                )
                
                completion(.success(document))
            }
        }
    }
    
    func downloadDocument(document: Document, completion: @escaping (Result<Data, GoogleDriveError>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        guard let fileId = document.googleDriveFileId else {
            completion(.failure(.invalidFileId))
            return
        }
        
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)
        
        driveService.executeQuery(query) { [weak self] (ticket, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(GoogleDriveError.downloadFailed))
                    return
                }
                
                guard let data = (result as? GTLRDataObject)?.data else {
                    completion(.failure(GoogleDriveError.downloadFailed))
                    return
                }
                
                completion(.success(data))
            }
        }
    }
    
    func listDocuments(completion: @escaping (Result<[Document], GoogleDriveError>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(GoogleDriveError.notAuthenticated))
            return
        }
        
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.fields = "files(id,name,mimeType,createdTime,modifiedTime,size,parents)"
        query.q = "trashed=false"
        
        driveService.executeQuery(query) { [weak self] (ticket, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let fileList = result as? GTLRDrive_FileList,
                      let files = fileList.files else {
                    completion(.success([]))
                    return
                }
                
                let documents = files.compactMap { file -> Document? in
                    guard let id = file.identifier,
                          let name = file.name else { return nil }
                    
                    let type = self?.documentType(from: file.mimeType) ?? .other
                    let createdDate = file.createdTime?.date ?? Date()
                    let modifiedDate = file.modifiedTime?.date ?? Date()
                    let parentId = file.parents?.first
                    
                    return Document(
                        id: UUID().uuidString,
                        name: name,
                        type: type,
                        venueType: nil,
                        description: nil,
                        googleDriveFileId: id,
                        googleDriveUrl: "https://drive.google.com/file/d/\(id)/view",
                        mimeType: file.mimeType ?? "application/octet-stream",
                        groupId: AppState.shared.user?.groupId ?? "",
                        createdBy: AppState.shared.user?.id ?? "",
                        createdAt: createdDate,
                        updatedAt: modifiedDate,
                        version: 1,
                        eventId: nil,
                        folderId: parentId,
                        isTemplate: false,
                        isPublic: false
                    )
                }
                
                completion(.success(documents))
            }
        }
    }
    
    func createFolder(name: String, completion: @escaping (Result<DocumentFolder, GoogleDriveError>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        let folder = GTLRDrive_File()
        folder.name = name
        folder.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        
        driveService.executeQuery(query) { [weak self] (ticket, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let driveFolder = result as? GTLRDrive_File,
                      let folderId = driveFolder.identifier else {
                    completion(.failure(GoogleDriveError.uploadFailed))
                    return
                }
                
                let documentFolder = DocumentFolder(
                    id: UUID().uuidString,
                    name: name,
                    type: nil,
                    eventId: nil,
                    groupId: AppState.shared.user?.groupId ?? "",
                    parentFolderId: nil,
                    googleDriveFolderId: folderId,
                    createdAt: Date(),
                    isSystemFolder: false
                )
                
                completion(.success(documentFolder))
            }
        }
    }
    
    func deleteDocument(document: Document, completion: @escaping (Result<Void, GoogleDriveError>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        guard let googleDriveFileId = document.googleDriveFileId, !googleDriveFileId.isEmpty else {
            completion(.failure(.invalidFileId))
            return
        }
        
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: googleDriveFileId)
        
        driveService.executeQuery(query) { [weak self] (ticket, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Google Drive delete error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(.networkError(error)))
                    return
                }
                
                print("✅ Document deleted successfully from Google Drive")
                completion(.success(()))
            }
        }
    }
    
    func disconnect() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.errorMessage = nil
            
            UserDefaults.standard.removeObject(forKey: "GoogleDriveAuthenticated")
            UserDefaults.standard.removeObject(forKey: "GoogleDriveUserEmail")
        }
    }
    
    private func mimeType(for type: DocumentType, fileName: String? = nil) -> String {
        // Определяем MIME type по расширению файла, если доступно
        if let fileName = fileName {
            let lowercaseFileName = fileName.lowercased()
            
            // Изображения
            if lowercaseFileName.hasSuffix(".jpg") || lowercaseFileName.hasSuffix(".jpeg") {
                return "image/jpeg"
            } else if lowercaseFileName.hasSuffix(".png") {
                return "image/png"
            } else if lowercaseFileName.hasSuffix(".gif") {
                return "image/gif"
            } else if lowercaseFileName.hasSuffix(".heic") || lowercaseFileName.hasSuffix(".heif") {
                return "image/heic"
            }
            
            // Документы
            else if lowercaseFileName.hasSuffix(".pdf") {
                return "application/pdf"
            } else if lowercaseFileName.hasSuffix(".doc") {
                return "application/msword"
            } else if lowercaseFileName.hasSuffix(".docx") {
                return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            } else if lowercaseFileName.hasSuffix(".txt") {
                return "text/plain"
            }
            
            // Аудио
            else if lowercaseFileName.hasSuffix(".mp3") {
                return "audio/mpeg"
            } else if lowercaseFileName.hasSuffix(".wav") {
                return "audio/wav"
            } else if lowercaseFileName.hasSuffix(".m4a") {
                return "audio/mp4"
            }
            
            // Видео
            else if lowercaseFileName.hasSuffix(".mp4") {
                return "video/mp4"
            } else if lowercaseFileName.hasSuffix(".mov") {
                return "video/quicktime"
            }
        }
        
        // Fallback - используем универсальный тип для неизвестных файлов
        // Не пытаемся угадать тип по выбранному пользователем типу документа
        return "application/octet-stream"
    }
    
    private func documentType(from mimeType: String?) -> DocumentType {
        // Убираем автоматическое определение типа документа
        // Теперь всегда возвращаем .other, чтобы пользователь сам выбирал тип
        return .other
    }
    
    private func handleError(_ error: Error) -> GoogleDriveError {
        if let googleDriveError = error as? GoogleDriveError {
            return googleDriveError
        } else {
            return .networkError(error)
        }
    }
}

extension GoogleDriveService {
    @MainActor
    func loadDocuments() async {
        await withCheckedContinuation { continuation in
            listDocuments { result in
                switch result {
                case .success(let documents):
                    Task { @MainActor in
                        self.documents = documents
                    }
                case .failure(_):
                    Task { @MainActor in
                        self.documents = []
                    }
                }
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func refreshDocuments() async {
        await loadDocuments()
    }
    
    func uploadDocument(name: String, data: Data, type: DocumentType, completion: @escaping (Result<Document, Error>) -> Void) {
        uploadDocument(data: data, name: name, type: type) { result in
            switch result {
            case .success(let document):
                completion(.success(document))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func downloadDocument(_ document: Document, completion: @escaping (Result<Data, Error>) -> Void) {
        downloadDocument(document: document) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
