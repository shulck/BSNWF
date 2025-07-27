import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL
    private let content: (UIImage) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var didAttemptLoad = false
    @State private var loadFailed = false
    
    init(
        url: URL,
        @ViewBuilder content: @escaping (UIImage) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else if !loadFailed {
                placeholder()
            }
        }
        .onAppear {
            if !didAttemptLoad {
                didAttemptLoad = true
                Task { await loadImage() }
            }
        }
    }
    
    private func loadImage() async {
        if let cachedImage = await loadFromCoreData() {
            await MainActor.run { self.image = cachedImage }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check if we got a valid response
            if let httpResponse = response as? HTTPURLResponse {
                // If image was deleted from server, don't show placeholder
                if httpResponse.statusCode == 404 || httpResponse.statusCode >= 400 {
                    await MainActor.run {
                        self.image = nil
                        self.loadFailed = true
                    }
                    return
                }
            }
            
            if let uiImage = UIImage(data: data) {
                await saveToCoreData(imageData: data)
                await MainActor.run { self.image = uiImage }
            }
        } catch {
            // Don't show placeholder for failed loads
            await MainActor.run {
                self.image = nil
                self.loadFailed = true
            }
        }
    }
    
    private func loadFromCoreData() async -> UIImage? {
        // Simple in-memory cache lookup using URL as key
        return ImageCache.shared.image(for: url)
    }

    private func saveToCoreData(imageData: Data) async {
        // Save to in-memory cache
        if let image = UIImage(data: imageData) {
            ImageCache.shared.setImage(image, for: url)
        }
    }
}

// Simple in-memory image cache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100 // Limit number of cached images
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
