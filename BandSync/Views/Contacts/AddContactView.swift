import SwiftUI

struct AddContactView: View {
    @Binding var isPresented: Bool
    @StateObject private var contactService = ContactService.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role = "Musicians"
    @State private var company = ""
    @State private var contactSource = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Extended role list for band manager
    private let roles = [
        "Musicians",
        "Manager",
        "Band Members",
        "Producers",
        "Sound Engineers",
        "Recording Engineers",
        "Mixing Engineers",
        "Mastering Engineers",
        "Venue Owners",
        "Venue Managers",
        "Booking Agents",
        "Event Organizers",
        "Festival Coordinators",
        "Promoters",
        "Music Directors",
        "A&R Representatives",
        "Record Label Contacts",
        "Music Publishers",
        "Radio DJs",
        "Music Journalists",
        "Photographers",
        "Videographers",
        "Graphic Designers",
        "Web Developers",
        "Social Media Managers",
        "PR Specialists",
        "Music Lawyers",
        "Business Managers",
        "Accountants",
        "Tour Managers",
        "Roadies",
        "Instrument Technicians",
        "Lighting Technicians",
        "Merchandise Vendors",
        "Distribution Partners",
        "Streaming Platform Contacts",
        "Music Store Owners",
        "Equipment Suppliers",
        "Transportation Services",
        "Accommodation Contacts",
        "Fans & Supporters",
        "Industry Contacts",
        "Others"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic information
                Section("Contact Information".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter full name".localized, text: $name)
                            .textContentType(.name)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter email address".localized, text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter phone number".localized, text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Professional information
                Section("Professional Details".localized) {
                    Picker("Role/Position".localized, selection: $role) {
                        ForEach(roles, id: \.self) { role in
                            Text(role.localized).tag(role)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Company/Organization".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter company name".localized, text: $company)
                            .textContentType(.organizationName)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How did you meet/Source".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Contact source placeholder".localized, text: $contactSource)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Description and notes
                Section("Notes & Description".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description/Notes".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Contact notes placeholder".localized, text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Contact".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save".localized) {
                        saveContact()
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .disabled(name.isEmpty || isLoading)
                    .opacity((name.isEmpty || isLoading) ? 0.6 : 1.0)
                }
            }
            .overlay {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Saving contact...".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func saveContact() {
        guard let groupId = AppState.shared.user?.groupId else {
            errorMessage = "Could not determine group".localized
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name is required".localized
            return
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "Please enter a valid email address".localized
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let newContact = Contact(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            groupId: groupId,
            company: company.isEmpty ? nil : company.trimmingCharacters(in: .whitespacesAndNewlines),
            contactSource: contactSource.isEmpty ? nil : contactSource.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        contactService.addContact(newContact) { success in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    isPresented = false
                } else {
                    errorMessage = "Failed to save contact. Please try again.".localized
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
