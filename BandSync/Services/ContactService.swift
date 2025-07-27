import Foundation
import FirebaseFirestore

final class ContactService: ObservableObject {
    static let shared = ContactService()

    @Published var contacts: [Contact] = []

    private let db = Firestore.firestore()

    func fetchContacts(for groupId: String, completion: (() -> Void)? = nil) {
        db.collection("contacts")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                if let docs = snapshot?.documents {
                    let items = docs.compactMap { try? $0.data(as: Contact.self) }
                    DispatchQueue.main.async {
                        self?.contacts = items
                        #if DEBUG
                        print("[ContactService] Fetched \(items.count) contacts")
                        #endif
                        completion?()
                    }
                } else if let error = error {
                    #if DEBUG
                    print("[ContactService.fetchContacts] \(error.localizedDescription)")
                    #endif
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
    }

    func addContact(_ contact: Contact, completion: @escaping (Bool) -> Void) {
        guard !contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            #if DEBUG
            print("[ContactService] Contact name is required, skipping: \(contact.name)")
            #endif
            completion(false)
            return
        }
        
        let existingContact = contacts.first { existingContact in
            let nameMatch = existingContact.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                           contact.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let groupMatch = existingContact.groupId == contact.groupId
            
            let emailMatch = !contact.email.isEmpty && !existingContact.email.isEmpty &&
                           existingContact.email.lowercased() == contact.email.lowercased()
            
            return (nameMatch || emailMatch) && groupMatch
        }
        
        if existingContact != nil {
            #if DEBUG
            print("[ContactService] Similar contact already exists, skipping duplicate: \(contact.name)")
            #endif
            completion(false)
            return
        }
        
        do {
            _ = try db.collection("contacts").addDocument(from: contact) { error in
                if let error = error {
                    #if DEBUG
                    print("[ContactService.addContact] \(error.localizedDescription)")
                    #endif
                    completion(false)
                } else {
                    #if DEBUG
                    print("[ContactService] Contact added: \(contact.name)")
                    #endif
                    DispatchQueue.main.async {
                        self.fetchContacts(for: contact.groupId) {
                            completion(true)
                        }
                    }
                }
            }
        } catch {
            #if DEBUG
            print("[ContactService.addContact.serialization] \(error.localizedDescription)")
            #endif
            completion(false)
        }
    }

    func updateContact(_ contact: Contact, completion: @escaping (Bool) -> Void) {
        guard let id = contact.id else {
            #if DEBUG
            print("[ContactService] Cannot update contact without ID")
            #endif
            completion(false)
            return
        }
        do {
            try db.collection("contacts").document(id).setData(from: contact) { error in
                if let error = error {
                    #if DEBUG
                    print("[ContactService.updateContact] \(error.localizedDescription)")
                    #endif
                    completion(false)
                } else {
                    #if DEBUG
                    print("[ContactService] Contact updated: \(contact.name)")
                    #endif
                    self.fetchContacts(for: contact.groupId)
                    completion(true)
                }
            }
        } catch {
            #if DEBUG
            print("[ContactService.updateContact.serialization] \(error.localizedDescription)")
            #endif
            completion(false)
        }
    }

    func deleteContact(_ contact: Contact) {
        guard let id = contact.id else {
            #if DEBUG
            print("[ContactService] Cannot delete contact without ID")
            #endif
            return
        }
        db.collection("contacts").document(id).delete { error in
            if let error = error {
                #if DEBUG
                print("[ContactService.deleteContact] \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("[ContactService] Contact deleted: \(contact.name)")
                #endif
                if let groupId = AppState.shared.user?.groupId {
                    self.fetchContacts(for: groupId)
                }
            }
        }
    }

    func contactsForEvent(_ eventTag: String) -> [Contact] {
        return contacts.filter { $0.eventTag == eventTag }
    }
    
    func contactCountForEvent(_ eventTag: String) -> Int {
        return contacts.filter { $0.eventTag == eventTag }.count
    }
    
    func uniqueEventTags() -> [String] {
        let tags = contacts.compactMap { $0.eventTag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }
}
