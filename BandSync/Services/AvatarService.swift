//
//  AvatarService.swift
//  BandSync
//
//  Created by GitHub Copilot on 18.07.2025.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore

class AvatarService {
    static let shared = AvatarService()
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let imageCache = NSCache<NSString, UIImage>()
    private var cacheKeys = Set<String>() // Track cache keys
    
    private let maxImageSize: CGFloat = 512
    private let compressionQuality: CGFloat = 0.8
    
    private init() {
        imageCache.countLimit = 100 // Limit cache to 100 images
    }
    
    // MARK: - User Avatar Methods
    
    func uploadUserAvatar(_ image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = prepareAvatarImageData(image) else {
            completion(.failure(AvatarError.imageProcessingFailed))
            return
        }
        
        let fileName = "user_avatar_\(userId).jpg"
        let storagePath = "avatars/users/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "uploadDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(AvatarError.urlGenerationFailed))
                    return
                }
                
                // Update user document with avatar URL
                self?.updateUserAvatarURL(userId: userId, avatarURL: downloadURL) { result in
                    switch result {
                    case .success:
                        // Clear any cached avatar for this user
                        self?.clearCachedAvatar(userId: userId)
                        completion(.success(downloadURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func deleteUserAvatar(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fileName = "user_avatar_\(userId).jpg"
        let storagePath = "avatars/users/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        storageRef.delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Remove avatar URL from user document
            self?.updateUserAvatarURL(userId: userId, avatarURL: nil) { result in
                // Clear any cached avatar for this user
                self?.clearCachedAvatar(userId: userId)
                completion(result)
            }
        }
    }
    
    // MARK: - Group Logo Methods
    
    func uploadGroupLogo(_ image: UIImage, groupId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = prepareAvatarImageData(image) else {
            completion(.failure(AvatarError.imageProcessingFailed))
            return
        }
        
        let fileName = "group_logo_\(groupId).jpg"
        let storagePath = "avatars/groups/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "groupId": groupId,
            "uploadDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(AvatarError.urlGenerationFailed))
                    return
                }
                
                // Update group document with logo URL
                self?.updateGroupLogoURL(groupId: groupId, logoURL: downloadURL) { result in
                    switch result {
                    case .success:
                        completion(.success(downloadURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func deleteGroupLogo(groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fileName = "group_logo_\(groupId).jpg"
        let storagePath = "avatars/groups/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        storageRef.delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Remove logo URL from group document
            self?.updateGroupLogoURL(groupId: groupId, logoURL: nil) { result in
                completion(result)
            }
        }
    }
    
    // MARK: - Image Download and Cache
    
    func downloadAvatar(from url: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: url as NSString) {
            completion(cachedImage)
            return
        }
        
        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, error in
            guard let data = data, 
                  let image = UIImage(data: data),
                  error == nil else {
                completion(nil)
                return
            }
            
            // Cache the image
            self?.imageCache.setObject(image, forKey: url as NSString)
            self?.cacheKeys.insert(url)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func prepareAvatarImageData(_ image: UIImage) -> Data? {
        let resizedImage = resizeImage(image, targetSize: maxImageSize)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: targetSize, height: targetSize / aspectRatio)
        } else {
            newSize = CGSize(width: targetSize * aspectRatio, height: targetSize)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func updateUserAvatarURL(userId: String, avatarURL: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let userData: [String: Any] = [
            "avatarURL": avatarURL ?? NSNull()
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func updateGroupLogoURL(groupId: String, logoURL: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let groupData: [String: Any] = [
            "logoURL": logoURL ?? NSNull()
        ]
        
        db.collection("groups").document(groupId).updateData(groupData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        cacheKeys.removeAll()
    }
    
    func clearCachedAvatar(userId: String) {
        // Clear any cached images for this user
        let keysToRemove = cacheKeys.filter { $0.contains(userId) }
        
        for key in keysToRemove {
            imageCache.removeObject(forKey: key as NSString)
            cacheKeys.remove(key)
        }
    }
}

// MARK: - Avatar Errors

enum AvatarError: LocalizedError {
    case imageProcessingFailed
    case urlGenerationFailed
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .urlGenerationFailed:
            return "Failed to generate download URL"
        case .uploadFailed:
            return "Failed to upload avatar"
        case .downloadFailed:
            return "Failed to download avatar"
        }
    }
}
