import SwiftUI
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredBarTintColor = UIColor.systemBackground
        safariVC.preferredControlTintColor = UIColor.systemBlue
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Safari view controller doesn't need updates
    }
}

struct SafariWebView_Previews: PreviewProvider {
    static var previews: some View {
        SafariWebView(url: URL(string: NSLocalizedString("previewWebsiteURL", comment: "Preview website URL for Safari view"))!)
    }
}
