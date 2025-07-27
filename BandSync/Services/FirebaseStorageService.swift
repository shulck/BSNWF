import Foundation
import UIKit
import FirebaseStorage

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage()
    
    private let maxImageSize: CGFloat = 1280
    private let compressionQuality: CGFloat = 0.7
    
    private let chatMaxSize: CGFloat = 1200
    private let chatCompressionQuality: CGFloat = 0.6
    private let maxChatFileSize = 800 * 1024
    
    private init() {}
    
    func uploadReceiptImage(_ image: UIImage, recordId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = prepareImageData(image) else {
            completion(nil)
            return
        }
        
        let fileName = "receipt_\(recordId).jpg"
        let storagePath = "receipts/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "recordId": recordId,
            "uploadDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if error != nil {
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if error != nil {
                    completion(nil)
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(nil)
                    return
                }
                
                completion(downloadURL)
            }
        }
    }
    
    func downloadReceiptImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard URL(string: url) != nil else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if error != nil {
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            completion(image)
        }
    }
    
    func deleteReceiptImage(url: String, completion: @escaping (Bool) -> Void) {
        guard !url.isEmpty else {
            completion(false)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        
        storageRef.delete { error in
            if error != nil {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    func uploadChatImage(_ image: UIImage, chatId: String, messageId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = prepareChatImageData(image) else {
            completion(nil)
            return
        }
        
        let fileName = "chat_image_\(messageId).jpg"
        let storagePath = "chats/\(chatId)/images/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "chatId": chatId,
            "messageId": messageId,
            "uploadDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "originalSize": "\(image.size.width)x\(image.size.height)"
        ]
        
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if error != nil {
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if error != nil {
                    completion(nil)
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(nil)
                    return
                }
                
                completion(downloadURL)
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if snapshot.error != nil {
                completion(nil)
            }
        }
    }
    
    func uploadChatImageWithProgress(
        _ image: UIImage,
        chatId: String,
        messageId: String,
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (String?) -> Void
    ) {
        guard let imageData = prepareChatImageData(image) else {
            completion(nil)
            return
        }
        
        let fileName = "chat_image_\(messageId).jpg"
        let storagePath = "chats/\(chatId)/images/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if error != nil {
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if error != nil {
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
        
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            DispatchQueue.main.async {
                progressHandler(percentComplete)
            }
        }
    }
    
    func deleteChatImage(url: String, completion: @escaping (Bool) -> Void) {
        guard !url.isEmpty else {
            completion(false)
            return
        }
        
        guard url.contains("firebasestorage.googleapis.com") || url.contains("firebase") else {
            completion(false)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        
        storageRef.delete { error in
            if let error = error {
                let nsError = error as NSError
                
                if nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    completion(true)
                } else {
                    completion(false)
                }
                return
            }
            
            completion(true)
        }
    }

    private func prepareImageData(_ image: UIImage) -> Data? {
        let resizedImage = resizeImage(image, targetSize: maxImageSize)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        return imageData
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize / size.width
        let heightRatio = targetSize / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        if scaleFactor >= 1 {
            return image
        }
        
        let scaledWidth = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor
        let targetRect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scaledWidth, height: scaledHeight), false, 1.0)
        image.draw(in: targetRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func prepareChatImageData(_ image: UIImage) -> Data? {
        let resizedImage = resizeImage(image, targetSize: chatMaxSize)
        
        var compression = chatCompressionQuality
        
        guard var imageData = resizedImage.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        var attempts = 0
        let maxAttempts = 5
        
        while imageData.count > maxChatFileSize && compression > 0.3 && attempts < maxAttempts {
            compression -= 0.1
            if let newData = resizedImage.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
            attempts += 1
        }
        
        if imageData.count > maxChatFileSize {
            let smallerImage = resizeImage(image, targetSize: 1000)
            if let smallerData = smallerImage.jpegData(compressionQuality: 0.5) {
                imageData = smallerData
            }
        }
        
        if imageData.count > maxChatFileSize * 2 {
            let emergencyImage = resizeImage(image, targetSize: 800)
            if let emergencyData = emergencyImage.jpegData(compressionQuality: 0.4) {
                imageData = emergencyData
            }
        }
        
        return imageData
    }
    
    static func isFirebaseStorageURL(_ url: String) -> Bool {
        return url.contains("firebasestorage.googleapis.com") ||
               url.contains("firebase") ||
               url.contains("appspot.com")
    }
    
    static func extractStoragePath(from url: String) -> String? {
        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/o/").last else {
            return nil
        }
        
        return path.removingPercentEncoding
    }
    
    func getImageMetadata(from url: String, completion: @escaping (StorageMetadata?) -> Void) {
        guard !url.isEmpty else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        
        storageRef.getMetadata { metadata, error in
            if error != nil {
                completion(nil)
                return
            }
            
            completion(metadata)
        }
    }
    
    func checkIfImageExists(at url: String, completion: @escaping (Bool) -> Void) {
        guard !url.isEmpty else {
            completion(false)
            return
        }
        
        let storageRef = Storage.storage().reference(forURL: url)
        
        storageRef.getMetadata { metadata, error in
            if error != nil {
                completion(false)
            } else {
                completion(metadata != nil)
            }
        }
    }
    
    func deleteChatImages(urls: [String], completion: @escaping (Int, Int) -> Void) {
        let group = DispatchGroup()
        var successCount = 0
        var failureCount = 0
        
        for url in urls {
            group.enter()
            deleteChatImage(url: url) { success in
                if success {
                    successCount += 1
                } else {
                    failureCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(successCount, failureCount)
        }
    }
    
    func cleanupOldChatImages(chatId: String, olderThan date: Date, completion: @escaping (Int) -> Void) {
        let chatImagesRef = storage.reference().child("chats/\(chatId)/images")
        
        chatImagesRef.listAll { result, error in
            if error != nil {
                completion(0)
                return
            }
            
            guard let items = result?.items else {
                completion(0)
                return
            }
            
            let group = DispatchGroup()
            var deletedCount = 0
            
            for item in items {
                group.enter()
                
                item.getMetadata { metadata, error in
                    defer { group.leave() }
                    
                    if let metadata = metadata,
                       let timeCreated = metadata.timeCreated,
                       timeCreated < date {
                        
                        item.delete { error in
                            if error == nil {
                                deletedCount += 1
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(deletedCount)
            }
        }
    }
}
