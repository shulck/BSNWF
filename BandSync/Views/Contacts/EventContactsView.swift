//
//  EventContactsView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 12.05.2025.
//

import SwiftUI

struct EventContactsView: View {
    @StateObject private var contactService = ContactService.shared
    let eventTitle: String
    let eventType: String
    
    @State private var isLoading = true
    @State private var contacts: [Contact] = []
    
    // Grouped contacts by role
    private var groupedContacts: [String: [Contact]] {
        Dictionary(grouping: contacts) { $0.role }
    }
    
    // Sorted role keys
    private var sortedRoles: [String] {
        groupedContacts.keys.sorted()
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if contacts.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No contacts for this event".localized)
                        .font(.headline)
                    
                    Text("No contacts are associated with this event.".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                List {
                    ForEach(sortedRoles, id: \.self) { role in
                        Section(header: Text(role)) {
                            ForEach(groupedContacts[role] ?? []) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.headline)
                                        
                                        Text(contact.phone)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Event Contacts".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadContacts()
        }
    }
    
    // Load contacts specific to this event
    private func loadContacts() {
        isLoading = true
        
        // Ensure contacts are loaded
        if contactService.contacts.isEmpty, let groupId = AppState.shared.user?.groupId {
            contactService.fetchContacts(for: groupId) {
                filterContacts()
            }
        } else {
            filterContacts()
        }
    }
    
    // Filter contacts for this specific event
    private func filterContacts() {
        contacts = contactService.contacts.filter { contact in
            contact.eventTag == eventTitle
        }
        
        isLoading = false
    }
}
