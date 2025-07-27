import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()
    let storage = Storage.storage()
    
    private init() {}
    
    // Generic image upload function for various modules (not chat-specific)
    
    func deleteImage(url: String, completion: @escaping (Error?) -> Void) {
        let imageRef = storage.reference(forURL: url)
        
        imageRef.delete { error in
            completion(error)
        }
    }
} 
