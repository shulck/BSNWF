//
//  ChatSearchView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 26.06.2025.
//

import SwiftUI
import FirebaseAuth

struct ChatSearchView: View {
    let chat: Chat
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = ChatService.shared
    
    @State private var searchText = ""
    @State private var searchResults: [Message] = []
    @State private var isSearching = false
    @State private var selectedMessage: Message?
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                    .padding(.horizontal)
                
                if isSearching {
                    // Loading indicator
                    VStack {
                        ProgressView()
                        Text("Searching...".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    // No results
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Nothing found".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try changing your search query".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    // Search results
                    List(searchResults, id: \.id) { message in
                        SearchResultRow(
                            message: message,
                            searchQuery: searchText,
                            chat: chat,
                            onTap: { selectedMessage = message }
                        )
                    }
                } else {
                    // Initial state
                    VStack {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Search messages".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Enter text to search in this chat".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search in chat".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedMessage) { message in
            MessageDetailView(message: message, chat: chat)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        chatService.searchMessages(in: chat.id ?? "", query: searchText) { results in
            DispatchQueue.main.async {
                self.searchResults = results.sorted { $0.timestamp > $1.timestamp }
                self.isSearching = false
            }
        }
    }
}

struct SearchResultRow: View {
    let message: Message
    let searchQuery: String
    let chat: Chat
    let onTap: () -> Void
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var isCurrentUser: Bool {
        message.senderID == currentUserId
    }
    
    private var senderName: String {
        if isCurrentUser {
            return "You".localized
        }
        return message.senderName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(senderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? .blue : .green)
                
                Spacer()
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Main content with search query highlighting
            HighlightedText(text: message.content, highlight: searchQuery)
                .font(.body)
                .lineLimit(3)
            
            if message.imageURL != nil {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.blue)
                    Text("Image".localized)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday".localized
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct HighlightedText: View {
    let text: String
    let highlight: String
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
        } else {
            let parts = text.components(separatedBy: highlight)
            
            if parts.count > 1 {
                // There are matches to highlight
                HStack(spacing: 0) {
                    ForEach(0..<parts.count, id: \.self) { index in
                        Text(parts[index])
                        
                        if index < parts.count - 1 {
                            Text(highlight)
                                .background(Color.yellow.opacity(0.3))
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                Text(text)
            }
        }
    }
}

struct MessageDetailView: View {
    let message: Message
    let chat: Chat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Message information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Information".localized)
                            .font(.headline)
                        
                        HStack {
                            Text("From:".localized)
                            Spacer()
                            Text(message.senderName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Time:".localized)
                            Spacer()
                            Text(formatFullDate(message.timestamp))
                                .foregroundColor(.secondary)
                        }
                        
                        if message.isEdited {
                            HStack {
                                Text("Edited:".localized)
                                Spacer()
                                Text(message.editedAt != nil ? formatFullDate(message.editedAt!) : "Yes".localized)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Message content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content".localized)
                            .font(.headline)
                        
                        if !message.content.isEmpty {
                            Text(message.content)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if let imageURL = message.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Message".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: (() -> Void)?
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search messages...".localized
        searchBar.searchBarStyle = .minimal
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            parent.onSearchButtonClicked?()
        }
    }
}

#Preview {
    let sampleChat = Chat(
        id: "chat1",
        type: .group,
        participants: ["user1", "user2", "user3"],
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        name: "Test Chat"
    )
    
    ChatSearchView(chat: sampleChat)
}
