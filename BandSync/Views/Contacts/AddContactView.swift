import SwiftUI

struct AddContactView: View {
    @Binding var isPresented: Bool
    @StateObject private var contactService = ContactService.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role = NSLocalizedString("roleMusicians", comment: "Musicians role")
    @State private var company = ""
    @State private var contactSource = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Extended role list for band manager
    private let roles = [
        NSLocalizedString("roleMusicians", comment: "Musicians role"),
        NSLocalizedString("roleManager", comment: "Manager role"),
        NSLocalizedString("roleBandMembers", comment: "Band Members role"),
        NSLocalizedString("roleProducers", comment: "Producers role"),
        NSLocalizedString("roleSoundEngineers", comment: "Sound Engineers role"),
        NSLocalizedString("roleRecordingEngineers", comment: "Recording Engineers role"),
        NSLocalizedString("roleMixingEngineers", comment: "Mixing Engineers role"),
        NSLocalizedString("roleMasteringEngineers", comment: "Mastering Engineers role"),
        NSLocalizedString("roleVenueOwners", comment: "Venue Owners role"),
        NSLocalizedString("roleVenueManagers", comment: "Venue Managers role"),
        NSLocalizedString("roleBookingAgents", comment: "Booking Agents role"),
        NSLocalizedString("roleEventOrganizers", comment: "Event Organizers role"),
        NSLocalizedString("roleFestivalCoordinators", comment: "Festival Coordinators role"),
        NSLocalizedString("rolePromoters", comment: "Promoters role"),
        NSLocalizedString("roleMusicDirectors", comment: "Music Directors role"),
        NSLocalizedString("roleARRepresentatives", comment: "A&R Representatives role"),
        NSLocalizedString("roleRecordLabelContacts", comment: "Record Label Contacts role"),
        NSLocalizedString("roleMusicPublishers", comment: "Music Publishers role"),
        NSLocalizedString("roleRadioDJs", comment: "Radio DJs role"),
        NSLocalizedString("roleMusicJournalists", comment: "Music Journalists role"),
        NSLocalizedString("rolePhotographers", comment: "Photographers role"),
        NSLocalizedString("roleVideographers", comment: "Videographers role"),
        NSLocalizedString("roleGraphicDesigners", comment: "Graphic Designers role"),
        NSLocalizedString("roleWebDevelopers", comment: "Web Developers role"),
        NSLocalizedString("roleSocialMediaManagers", comment: "Social Media Managers role"),
        NSLocalizedString("rolePRSpecialists", comment: "PR Specialists role"),
        NSLocalizedString("roleMusicLawyers", comment: "Music Lawyers role"),
        NSLocalizedString("roleBusinessManagers", comment: "Business Managers role"),
        NSLocalizedString("roleAccountants", comment: "Accountants role"),
        NSLocalizedString("roleTourManagers", comment: "Tour Managers role"),
        NSLocalizedString("roleRoadies", comment: "Roadies role"),
        NSLocalizedString("roleInstrumentTechnicians", comment: "Instrument Technicians role"),
        NSLocalizedString("roleLightingTechnicians", comment: "Lighting Technicians role"),
        NSLocalizedString("roleMerchandiseVendors", comment: "Merchandise Vendors role"),
        NSLocalizedString("roleDistributionPartners", comment: "Distribution Partners role"),
        NSLocalizedString("roleStreamingPlatformContacts", comment: "Streaming Platform Contacts role"),
        NSLocalizedString("roleMusicStoreOwners", comment: "Music Store Owners role"),
        NSLocalizedString("roleEquipmentSuppliers", comment: "Equipment Suppliers role"),
        NSLocalizedString("roleTransportationServices", comment: "Transportation Services role"),
        NSLocalizedString("roleAccommodationContacts", comment: "Accommodation Contacts role"),
        NSLocalizedString("roleFansAndSupporters", comment: "Fans & Supporters role"),
        NSLocalizedString("roleIndustryContacts", comment: "Industry Contacts role"),
        NSLocalizedString("roleOthers", comment: "Others role")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic information
                Section(NSLocalizedString("contactInformation", comment: "Contact Information section")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("fullName", comment: "Full Name label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("enterFullName", comment: "Enter full name placeholder"), text: $name)
                            .textContentType(.name)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("emailAddress", comment: "Email Address label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("enterEmailAddress", comment: "Enter email address placeholder"), text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("phoneNumber", comment: "Phone Number label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("enterPhoneNumber", comment: "Enter phone number placeholder"), text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Professional information
                Section(NSLocalizedString("professionalDetails", comment: "Professional Details section")) {
                    Picker(NSLocalizedString("rolePosition", comment: "Role/Position picker label"), selection: $role) {
                        ForEach(roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("companyOrganization", comment: "Company/Organization label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("enterCompanyName", comment: "Enter company name placeholder"), text: $company)
                            .textContentType(.organizationName)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("howDidYouMeetSource", comment: "How did you meet/Source label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("contactSourcePlaceholder", comment: "Contact source placeholder"), text: $contactSource)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Description and notes
                Section(NSLocalizedString("notesDescription", comment: "Notes & Description section")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("descriptionNotes", comment: "Description/Notes label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("contactNotesPlaceholder", comment: "Contact notes placeholder"), text: $description, axis: .vertical)
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
            .navigationTitle(NSLocalizedString("addContact", comment: "Add Contact title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save", comment: "Save button")) {
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
                        
                        Text(NSLocalizedString("savingContact", comment: "Saving contact progress message"))
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
            errorMessage = NSLocalizedString("couldNotDetermineGroup", comment: "Could not determine group error")
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = NSLocalizedString("nameIsRequired", comment: "Name is required error")
            return
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = NSLocalizedString("pleaseEnterValidEmail", comment: "Please enter a valid email address error")
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
                    errorMessage = NSLocalizedString("failedToSaveContact", comment: "Failed to save contact error")
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
