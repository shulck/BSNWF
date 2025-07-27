import SwiftUI

struct MerchImageView: View {
    let imageUrl: String
    let item: MerchItem?
    @State private var uiImage: UIImage?
    
    init(imageUrl: String, item: MerchItem? = nil) {
        self.imageUrl = imageUrl
        self.item = item
    }
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
                    .task {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        // First check the passed item
        if let directItem = item,
           let base64Strings = directItem.imageBase64,
           !base64Strings.isEmpty {
            // If URL contains image index
            if let imageIndex = extractImageIndex(from: imageUrl),
               imageIndex < base64Strings.count {
                if let data = Data(base64Encoded: base64Strings[imageIndex]),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.uiImage = image
                    }
                }
                return
            }
            // If index not found but at least one image exists, use the first one
            else if !base64Strings.isEmpty {
                if let data = Data(base64Encoded: base64Strings[0]),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.uiImage = image
                    }
                }
                return
            }
        }
        
        // If this is a base64 URL, try to find the item by ID
        if imageUrl.hasPrefix("base64://") {
            if let itemId = extractItemId(from: imageUrl) {
                // Search for the item in the service
                if let matchingItem = MerchService.shared.items.first(where: { $0.id == itemId }),
                   let base64Strings = matchingItem.imageBase64,
                   !base64Strings.isEmpty {
                    
                    let imageIndex = extractImageIndex(from: imageUrl) ?? 0
                    if imageIndex < base64Strings.count {
                        if let data = Data(base64Encoded: base64Strings[imageIndex]),
                           let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.uiImage = image
                            }
                        }
                        return
                    }
                }
            }
        }
        
        // If all previous methods failed, try to load from URL
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
    
    // Helper functions
    private func extractItemId(from url: String) -> String? {
        // URL format "base64://itemId_index"
        let components = url.replacingOccurrences(of: "base64://", with: "").components(separatedBy: "_")
        return components.first
    }
    
    private func extractImageIndex(from url: String) -> Int? {
        // URL format "base64://itemId_index"
        let components = url.replacingOccurrences(of: "base64://", with: "").components(separatedBy: "_")
        if components.count > 1, let index = Int(components[1]) {
            return index
        }
        return nil
    }
}
