import SwiftUI
import Contacts
import ContactsUI

struct ContactsView: View {
    @StateObject private var contactService = ContactService.shared
    @StateObject private var eventService = EventService.shared
    @State private var searchText = ""
    @State private var showAddContact = false
    @State private var showImportContacts = false
    @State private var isLoading = false
    @State private var selectedFilter: ContactFilter = .all
    
    enum ContactFilter: String, CaseIterable {
        case all = "All"
        case events = "Events"
        case general = "General"
        
        var displayName: String {
            switch self {
            case .all: return "All Contacts".localized
            case .events: return "Event Contacts".localized
            case .general: return "General Contacts".localized
            }
        }
    }
    
    // Get unique event tags from contacts
    private var eventTags: [String] {
        var tags = Set<String>()
        for contact in contactService.contacts {
            if let tag = contact.eventTag, !tag.isEmpty {
                tags.insert(tag)
            }
        }
        return Array(tags).sorted { tag1, tag2 in
            // Sort by date if we can find the event, otherwise alphabetically
            if let event1 = eventService.events.first(where: { $0.title == tag1 }),
               let event2 = eventService.events.first(where: { $0.title == tag2 }) {
                return event1.date > event2.date // Most recent first
            }
            return tag1 < tag2
        }
    }
    
    // Filtered event tags
    private var filteredEventTags: [String] {
        if searchText.isEmpty {
            return eventTags
        } else {
            return eventTags.filter { eventTag in
                eventTag.lowercased().contains(searchText.lowercased()) ||
                contactService.contacts.filter({ $0.eventTag == eventTag }).contains { contact in
                    contact.name.lowercased().contains(searchText.lowercased()) ||
                    contact.email.lowercased().contains(searchText.lowercased()) ||
                    contact.phone.contains(searchText)
                }
            }
        }
    }
    
    // General contacts (without event tags)
    private var generalContacts: [Contact] {
        return contactService.contacts.filter { contact in
            contact.eventTag == nil || contact.eventTag?.isEmpty == true
        }.filter { contact in
            searchText.isEmpty ||
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.email.lowercased().contains(searchText.lowercased()) ||
            contact.phone.contains(searchText) ||
            (contact.company?.lowercased().contains(searchText.lowercased()) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Contact Type".localized, selection: $selectedFilter) {
                ForEach(ContactFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Content based on selected filter
            List {
                switch selectedFilter {
                case .all:
                    // Show both general and event contacts
                    if !generalContacts.isEmpty {
                        Section("General Contacts".localized) {
                            ForEach(generalContacts, id: \.id) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactRowView(contact: contact)
                                }
                            }
                        }
                    }
                    
                    if !filteredEventTags.isEmpty {
                        Section("Event Contacts".localized) {
                            ForEach(filteredEventTags, id: \.self) { eventTag in
                                NavigationLink(destination: EventContactsDetailView(eventTag: eventTag, contacts: contactService.contacts.filter { $0.eventTag == eventTag })) {
                                    EventContactRowView(
                                        eventTag: eventTag,
                                        contacts: contactService.contacts.filter { $0.eventTag == eventTag },
                                        eventType: getEventType(eventTag: eventTag, contacts: contactService.contacts)
                                    )
                                }
                            }
                        }
                    }
                    
                case .general:
                    // Show only general contacts
                    if !generalContacts.isEmpty {
                        Section("General Contacts".localized) {
                            ForEach(generalContacts, id: \.id) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactRowView(contact: contact)
                                }
                            }
                        }
                    } else {
                        emptyStateView(message: "No general contacts found".localized)
                    }
                    
                case .events:
                    // Show only event contacts
                    if !filteredEventTags.isEmpty {
                        Section("Event Contacts".localized) {
                            ForEach(filteredEventTags, id: \.self) { eventTag in
                                NavigationLink(destination: EventContactsDetailView(eventTag: eventTag, contacts: contactService.contacts.filter { $0.eventTag == eventTag })) {
                                    EventContactRowView(
                                        eventTag: eventTag,
                                        contacts: contactService.contacts.filter { $0.eventTag == eventTag },
                                        eventType: getEventType(eventTag: eventTag, contacts: contactService.contacts)
                                    )
                                }
                            }
                        }
                    } else {
                        emptyStateView(message: "No event contacts found".localized)
                    }
                }
                
                // Empty state for completely empty contacts
                if contactService.contacts.isEmpty {
                    emptyStateView(message: "No contacts yet".localized)
                }
            }
        }
        .navigationTitle("Contacts".localized)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search contacts".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showAddContact = true
                    }) {
                        Label("Add Contact".localized, systemImage: "person.badge.plus")
                    }
                    
                    Button(action: {
                        showImportContacts = true
                    }) {
                        Label("Import from Phone".localized, systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadContacts()
        }
        .refreshable {
            loadContacts()
        }
        .sheet(isPresented: $showAddContact) {
            AddContactView(isPresented: $showAddContact)
                .onDisappear {
                    loadContacts()
                }
        }
        .sheet(isPresented: $showImportContacts) {
            ContactPickerView { contact in
                if let contact = contact {
                    importSystemContact(contact)
                }
                showImportContacts = false
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            }
        }
    }
    
    // Empty state view
    private func emptyStateView(message: String) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: getEmptyStateIcon())
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                
                Text(getEmptyStateTitle())
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedFilter {
        case .all: return "person.2.slash"
        case .general: return "person.slash"
        case .events: return "calendar.badge.exclamationmark"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case .all: return "No Contacts".localized
        case .general: return "No General Contacts".localized
        case .events: return "No Event Contacts".localized
        }
    }
    
    // Load contacts and events
    private func loadContacts() {
        isLoading = true
        
        if let groupId = AppState.shared.user?.groupId {
            eventService.fetchEvents(for: groupId)
            contactService.fetchContacts(for: groupId) {
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
    
    // Import contact from system contact
    private func importSystemContact(_ contact: CNContact) {
        guard let groupId = AppState.shared.user?.groupId else { return }
        
        let firstName = contact.givenName
        let lastName = contact.familyName
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        var phoneNumber = ""
        if let phone = contact.phoneNumbers.first?.value.stringValue {
            phoneNumber = phone
        }
        
        var emailAddress = ""
        if let email = contact.emailAddresses.first?.value as String? {
            emailAddress = email
        }
        
        let newContact = Contact(
            name: fullName,
            email: emailAddress,
            phone: phoneNumber,
            role: "Others",
            groupId: groupId
        )
        
        contactService.addContact(newContact) { _ in }
    }
    
    private func getEventDate(for eventTag: String) -> Date? {
        return eventService.events.first(where: { $0.title == eventTag })?.date
    }
    
    func getEventType(eventTag: String, contacts: [Contact]) -> String? {
        return contacts.first(where: { $0.eventTag == eventTag })?.eventType
    }
}

// Event Contact Row in iOS style
struct EventContactRowView: View {
    let eventTag: String
    let contacts: [Contact]
    let eventType: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            eventIcon(for: eventType)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(eventTag)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let type = eventType {
                        Text(type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(contacts.count) contact\(contacts.count != 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func eventIcon(for eventType: String?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(getEventColor(for: eventType))
                .frame(width: 32, height: 32)
            
            Image(systemName: getIconName(for: eventType))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func getIconName(for eventType: String?) -> String {
        guard let type = eventType else { return "calendar" }
        
        switch type {
        case "Concert": return "music.note"
        case "Festival": return "flag.fill"
        case "Rehearsal": return "music.quarternote.3"
        case "Meeting": return "person.2.fill"
        case "Recording": return "waveform"
        case "Photoshoot": return "camera.fill"
        default: return "calendar"
        }
    }
    
    private func getEventColor(for eventType: String?) -> Color {
        guard let type = eventType else { return .gray }
        
        switch type {
        case "Concert": return .blue
        case "Festival": return .orange
        case "Rehearsal": return .green
        case "Meeting": return .purple
        case "Recording": return .red
        case "Photoshoot": return .pink
        default: return .gray
        }
    }
}

// Event Contacts Detail View in iOS style
struct EventContactsDetailView: View {
    let eventTag: String
    let contacts: [Contact]
    
    private var contactsByRole: [String: [Contact]] {
        Dictionary(grouping: contacts) { $0.role }
    }
    
    private var sortedRoles: [String] {
        contactsByRole.keys.sorted()
    }
    
    var body: some View {
        List {
            ForEach(sortedRoles, id: \.self) { role in
                Section(role) {
                    ForEach(contactsByRole[role] ?? [], id: \.id) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }
        }
        .navigationTitle(eventTag)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Contact Row for individual contacts in iOS style
struct ContactRowView: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with first letter
            contactAvatar
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.role)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !contact.phone.isEmpty {
                        Text(contact.phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !contact.email.isEmpty {
                        Text(contact.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var contactAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(getRoleColor(for: contact.role))
                .frame(width: 32, height: 32)
            
            Text(String(contact.name.prefix(1).uppercased()))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func getRoleColor(for role: String) -> Color {
        switch role {
        case "Musicians": return .orange
        case "Manager": return .blue
        case "Band Members": return .purple
        case "Producers": return .red
        case "Sound Engineers", "Recording Engineers", "Mixing Engineers", "Mastering Engineers":
            return .green
        case "Venue Owners", "Venue Managers": return .brown
        case "Booking Agents", "Event Organizers", "Festival Coordinators", "Promoters":
            return .indigo
        case "Music Directors", "A&R Representatives", "Record Label Contacts":
            return .pink
        default: return .gray
        }
    }
}
