import Foundation
import UIKit

final class LinkPreviewService {
    static let shared = LinkPreviewService()
    
    private let urlSession = URLSession.shared
    private var cache: [String: LinkPreview] = [:]
    
    private init() {}
    
    struct LinkPreview {
        let url: String
        let title: String?
        let description: String?
        let imageURL: String?
        let siteName: String?
    }
    
    func generatePreview(for urlString: String, completion: @escaping (LinkPreview?) -> Void) {
        if let cachedPreview = cache[urlString] {
            completion(cachedPreview)
            return
        }
        
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme.hasPrefix("http") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let htmlString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            let preview = self?.parseHTML(htmlString, originalURL: urlString)
            
            if let preview = preview {
                self?.cache[urlString] = preview
            }
            
            DispatchQueue.main.async {
                completion(preview)
            }
        }.resume()
    }
    
    private func parseHTML(_ html: String, originalURL: String) -> LinkPreview? {
        var title: String?
        var description: String?
        var imageURL: String?
        var siteName: String?
        
        if let titleRange = html.range(of: "<title[^>]*>([^<]*)</title>", options: .regularExpression) {
            let titleMatch = String(html[titleRange])
            if let contentRange = titleMatch.range(of: ">([^<]*)<", options: .regularExpression) {
                title = String(titleMatch[contentRange]).replacingOccurrences(of: ">", with: "").replacingOccurrences(of: "<", with: "")
            }
        }
        
        if let ogTitleRange = html.range(of: "property=\"og:title\"[^>]*content=\"([^\"]*)\"", options: .regularExpression) {
            let match = String(html[ogTitleRange])
            if let contentRange = match.range(of: "content=\"([^\"]*)\"", options: .regularExpression) {
                let content = String(match[contentRange])
                title = content.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }
        
        if let ogDescRange = html.range(of: "property=\"og:description\"[^>]*content=\"([^\"]*)\"", options: .regularExpression) {
            let match = String(html[ogDescRange])
            if let contentRange = match.range(of: "content=\"([^\"]*)\"", options: .regularExpression) {
                let content = String(match[contentRange])
                description = content.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }
        
        if let ogImageRange = html.range(of: "property=\"og:image\"[^>]*content=\"([^\"]*)\"", options: .regularExpression) {
            let match = String(html[ogImageRange])
            if let contentRange = match.range(of: "content=\"([^\"]*)\"", options: .regularExpression) {
                let content = String(match[contentRange])
                let imageUrl = content.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
                imageURL = resolveRelativeURL(imageUrl, baseURL: originalURL)
            }
        }
        
        if let ogSiteRange = html.range(of: "property=\"og:site_name\"[^>]*content=\"([^\"]*)\"", options: .regularExpression) {
            let match = String(html[ogSiteRange])
            if let contentRange = match.range(of: "content=\"([^\"]*)\"", options: .regularExpression) {
                let content = String(match[contentRange])
                siteName = content.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }
        
        guard let title = title, !title.isEmpty else {
            return nil
        }
        
        return LinkPreview(
            url: originalURL,
            title: title,
            description: description,
            imageURL: imageURL,
            siteName: siteName
        )
    }
    
    private func resolveRelativeURL(_ urlString: String, baseURL: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        
        if url.scheme != nil {
            return urlString
        }
        
        guard let base = URL(string: baseURL) else { return urlString }
        
        if let absoluteURL = URL(string: urlString, relativeTo: base)?.absoluteString {
            return absoluteURL
        }
        
        return urlString
    }
    
    func extractURLs(from text: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        } ?? []
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
