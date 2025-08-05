//
//  ContactDetailView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct ContactDetailView: View {
    @StateObject private var contactService = ContactService.shared
    @State private var contact: Contact
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    // For working with multiple phone numbers
    @State private var phoneNumbers: [String] = []
    @State private var showingAddPhone = false
    @State private var newPhoneNumber = ""
    
    init(contact: Contact) {
        _contact = State(initialValue: contact)
        _phoneNumbers = State(initialValue: parsePhoneNumbers(from: contact.phone))
    }
    
    var body: some View {
        List {
            // Basic Information
            Section(NSLocalizedString("information", comment: "Information section")) {
                if isEditing {
                    TextField(NSLocalizedString("name", comment: "Name field"), text: $contact.name)
                    TextField(NSLocalizedString("role", comment: "Role field"), text: $contact.role)
                } else {
                    LabeledContent(NSLocalizedString("name", comment: "Name label"), value: contact.name)
                    LabeledContent(NSLocalizedString("role", comment: "Role label"), value: contact.role)
                    
                    if let eventTag = contact.eventTag, !eventTag.isEmpty {
                        LabeledContent(NSLocalizedString("event", comment: "Event label"), value: eventTag)
                    }
                }
            }
            
            // Contact Details
            Section(NSLocalizedString("contactDetails", comment: "Contact Details section")) {
                if isEditing {
                    // In edit mode show all phone numbers
                    phoneNumbersEditSection
                    
                    TextField(NSLocalizedString("email", comment: "Email field"), text: $contact.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } else {
                    // In view mode show all phone numbers with action buttons
                    phoneNumbersViewSection
                    
                    if !contact.email.isEmpty {
                        Button {
                            sendEmail(to: contact.email)
                        } label: {
                            HStack {
                                Text(NSLocalizedString("email", comment: "Email label"))
                                Spacer()
                                Text(contact.email)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Professional Details
            if (contact.company != nil && !contact.company!.isEmpty) ||
               (contact.contactSource != nil && !contact.contactSource!.isEmpty) ||
               (contact.website != nil && !contact.website!.isEmpty) ||
               (contact.address != nil && !contact.address!.isEmpty) {
                Section(NSLocalizedString("professionalDetails", comment: "Professional Details section")) {
                    if isEditing {
                        TextField(NSLocalizedString("company", comment: "Company field"), text: Binding(
                            get: { contact.company ?? "" },
                            set: { contact.company = $0.isEmpty ? nil : $0 }
                        ))
                        TextField(NSLocalizedString("contactSourceEditPlaceholder", comment: "Contact source edit placeholder"), text: Binding(
                            get: { contact.contactSource ?? "" },
                            set: { contact.contactSource = $0.isEmpty ? nil : $0 }
                        ))
                        TextField(NSLocalizedString("website", comment: "Website field"), text: Binding(
                            get: { contact.website ?? "" },
                            set: { contact.website = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        TextField(NSLocalizedString("address", comment: "Address field"), text: Binding(
                            get: { contact.address ?? "" },
                            set: { contact.address = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .lineLimit(2...4)
                    } else {
                        if let company = contact.company, !company.isEmpty {
                            LabeledContent(NSLocalizedString("company", comment: "Company label"), value: company)
                        }
                        
                        if let contactSource = contact.contactSource, !contactSource.isEmpty {
                            LabeledContent(NSLocalizedString("contactSource", comment: "Contact Source label"), value: contactSource)
                        }
                        
                        if let website = contact.website, !website.isEmpty {
                            Button {
                                openWebsite(website)
                            } label: {
                                HStack {
                                    Text(NSLocalizedString("website", comment: "Website label"))
                                    Spacer()
                                    Text(website)
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if let address = contact.address, !address.isEmpty {
                            LabeledContent(NSLocalizedString("address", comment: "Address label"), value: address)
                        }
                    }
                }
            }
            
            // Notes
            Section(NSLocalizedString("notesDescription", comment: "Notes & Description section")) {
                if isEditing {
                    TextField(NSLocalizedString("contactNotesEditPlaceholder", comment: "Contact notes edit placeholder"), text: Binding(
                        get: { contact.description ?? "" },
                        set: { contact.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.vertical, 4)
                } else {
                    if let description = contact.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                    } else {
                        Text(NSLocalizedString("noNotesAdded", comment: "No notes added"))
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            
            // Quick Actions (only in view mode)
            if !isEditing && !phoneNumbers.isEmpty {
                Section(NSLocalizedString("quickActions", comment: "Quick Actions section")) {
                    // Show buttons for first number if multiple numbers exist
                    if let primaryPhone = phoneNumbers.first {
                        Button {
                            call(phone: primaryPhone)
                        } label: {
                            Label(phoneNumbers.count > 1 ? NSLocalizedString("callPrimary", comment: "Call (Primary)") : NSLocalizedString("call", comment: "Call"), systemImage: "phone")
                        }
                        
                        Button {
                            sendSMS(to: primaryPhone)
                        } label: {
                            Label(phoneNumbers.count > 1 ? NSLocalizedString("sendSMSPrimary", comment: "Send SMS (Primary)") : NSLocalizedString("sendSMS", comment: "Send SMS"), systemImage: "message")
                        }
                    }
                    
                    if !contact.email.isEmpty {
                        Button {
                            sendEmail(to: contact.email)
                        } label: {
                            Label(NSLocalizedString("sendEmail", comment: "Send Email"), systemImage: "envelope")
                        }
                    }
                }
                
                // Delete button
                if AppState.shared.hasEditPermission(for: .contacts) {
                    Section {
                        Button(NSLocalizedString("deleteContact", comment: "Delete Contact"), role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? NSLocalizedString("editContact", comment: "Edit Contact") : contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Edit/Save button
            if AppState.shared.hasEditPermission(for: .contacts) {
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button(NSLocalizedString("save", comment: "Save button")) {
                            saveChanges()
                        }
                    } else {
                        Button(NSLocalizedString("edit", comment: "Edit button")) {
                            isEditing = true
                        }
                    }
                }
            }
            
            // Cancel button (only in edit mode)
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        // Restore original data
                        if let original = contactService.contacts.first(where: { $0.id == contact.id }) {
                            contact = original
                            phoneNumbers = parsePhoneNumbers(from: original.phone)
                        }
                        isEditing = false
                    }
                }
            }
        }
        .alert(NSLocalizedString("deleteContactQuestion", comment: "Delete Contact?"), isPresented: $showingDeleteConfirmation) {
            Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {}
            Button(NSLocalizedString("delete", comment: "Delete"), role: .destructive) {
                deleteContact()
            }
        } message: {
            Text(NSLocalizedString("deleteContactConfirmation", comment: "Delete contact confirmation"))
        }
        .alert(NSLocalizedString("addPhoneNumber", comment: "Add Phone Number"), isPresented: $showingAddPhone) {
            TextField(NSLocalizedString("phoneNumber", comment: "Phone number"), text: $newPhoneNumber)
                .keyboardType(.phonePad)
            
            Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {
                newPhoneNumber = ""
            }
            
            Button(NSLocalizedString("add", comment: "Add")) {
                if !newPhoneNumber.isEmpty {
                    phoneNumbers.append(newPhoneNumber)
                    newPhoneNumber = ""
                }
            }
        }
        .onAppear {
            phoneNumbers = parsePhoneNumbers(from: contact.phone)
        }
    }
    
    // MARK: - Phone Numbers View Section
    private var phoneNumbersViewSection: some View {
        ForEach(Array(phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
            if !phoneNumber.isEmpty {
                Button {
                    call(phone: phoneNumber)
                } label: {
                    HStack {
                        Text(phoneNumbers.count > 1 ? String.localizedStringWithFormat(NSLocalizedString("phoneNumbered", comment: "Phone %d"), index + 1) : NSLocalizedString("phone", comment: "Phone"))
                        Spacer()
                        Text(phoneNumber)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Phone Numbers Edit Section
    private var phoneNumbersEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString("phoneNumbers", comment: "Phone Numbers"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showingAddPhone = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            if phoneNumbers.isEmpty {
                Text(NSLocalizedString("noPhoneNumbers", comment: "No phone numbers"))
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
                    HStack {
                        TextField(String.localizedStringWithFormat(NSLocalizedString("phoneNumbered", comment: "Phone %d"), index + 1), text: Binding(
                            get: { phoneNumbers[index] },
                            set: { phoneNumbers[index] = $0 }
                        ))
                        .keyboardType(.phonePad)
                        
                        // Call button
                        Button {
                            call(phone: phoneNumber)
                        } label: {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .disabled(phoneNumber.isEmpty)
                        
                        // Delete button
                        Button {
                            phoneNumbers.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func saveChanges() {
        // Combine all phone numbers back into main contact
        contact.phone = phoneNumbers.joined(separator: "\n")
        
        contactService.updateContact(contact) { success in
            if success {
                isEditing = false
            }
        }
    }
    
    private func deleteContact() {
        contactService.deleteContact(contact)
        dismiss()
    }
    
    private func call(phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func sendEmail(to: String) {
        if let url = URL(string: "mailto:\(to)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendSMS(to: String) {
        if let url = URL(string: "sms:\(to.replacingOccurrences(of: " ", with: ""))"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(_ website: String) {
        let urlString = website.hasPrefix("http") ? website : "https://\(website)"
        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Helper Functions
private func parsePhoneNumbers(from phoneString: String) -> [String] {
    let cleanString = phoneString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if cleanString.isEmpty {
        return []
    }
    
    let separators = ["\n", ",", ";", "|", " / ", " \\ "]
    var numbers = [cleanString]
    
    for separator in separators {
        var newNumbers: [String] = []
        for number in numbers {
            newNumbers.append(contentsOf: number.components(separatedBy: separator))
        }
        numbers = newNumbers
    }
    
    let filteredNumbers = numbers
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .filter { $0.count >= 7 }
    
    return filteredNumbers.isEmpty ? [cleanString] : filteredNumbers
}
