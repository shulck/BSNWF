import SwiftUI
import Foundation

struct LinkPreviewView: View {
    let preview: LinkPreviewService.LinkPreview
    @State private var showingSafari = false
    
    var body: some View {
        Button(action: {
            showingSafari = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                if let imageURL = preview.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 120)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    if let title = preview.title {
                        Text(title)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                    }
                    
                    // Description
                    if let description = preview.description {
                        Text(description)
                            .font(.caption)
                            .lineLimit(3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Site name
                    if let siteName = preview.siteName {
                        Text(siteName)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: preview.url) {
                SafariWebView(url: url)
            }
        }
    }
}

#Preview {
    LinkPreviewView(preview: LinkPreviewService.LinkPreview(
        url: "https://example.com",
        title: NSLocalizedString("exampleWebsite", comment: "Example website title for link preview"),
        description: NSLocalizedString("exampleWebsiteDescription", comment: "Example website description for link preview"),
        imageURL: nil,
        siteName: "example.com"
    ))
    .padding()
}
