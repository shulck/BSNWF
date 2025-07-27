//
//  ImageService.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 16.05.2025.
//

import SwiftUI
import UIKit

class ImageService {
    static let shared = ImageService()
    
    private init() {}
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    func encodeImageToBase64(_ image: UIImage, maxSize: CGFloat = 1024) -> String? {
        let resizedImage = resizeImage(image, targetSize: maxSize)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize / size.width
        let heightRatio = targetSize / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        if scaleFactor > 1 {
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
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
    }
}
