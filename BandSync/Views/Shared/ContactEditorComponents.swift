import SwiftUI

struct TempContact: Identifiable, Hashable {
    var id = UUID()
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var role: String = "Other"
    
    var isEmpty: Bool {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValid: Bool {
        let filledFields = [
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ].filter { $0 }.count
        
        return filledFields >= 2
    }
}

struct ContactEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var contact: TempContact
    let onSave: (TempContact) -> Void
    
    private let roleOptions = ["Other", "Production", "Sound Engineer", "Lighting Engineer", "Venue Staff", "Security", "Backstage", "Press"]
    
    init(contact: TempContact, onSave: @escaping (TempContact) -> Void) {
        _contact = State(initialValue: contact)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("contact_information", comment: "Header for contact information section"))) {
                    TextField("Name", text: $contact.name)
                    
                    TextField("Email", text: $contact.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $contact.phone)
                        .keyboardType(.phonePad)
                    
                    Picker("Role", selection: $contact.role) {
                        ForEach(roleOptions, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    
                    if contact.role == "Other" {
                        TextField("Custom Role", text: $contact.role)
                            .autocapitalization(.words)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("contact_details", comment: "Navigation title for contact details screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(contact)
                        dismiss()
                    }
                    .disabled(contact.name.isEmpty)
                }
            }
        }
    }
}
