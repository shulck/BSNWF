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
            Section("Information".localized) {
                if isEditing {
                    TextField("Name".localized, text: $contact.name)
                    TextField("Role".localized, text: $contact.role)
                } else {
                    LabeledContent("Name".localized, value: contact.name)
                    LabeledContent("Role".localized, value: contact.role)
                    
                    if let eventTag = contact.eventTag, !eventTag.isEmpty {
                        LabeledContent("Event".localized, value: eventTag)
                    }
                }
            }
            
            // Contact Details
            Section("Contact Details".localized) {
                if isEditing {
                    // In edit mode show all phone numbers
                    phoneNumbersEditSection
                    
                    TextField("Email".localized, text: $contact.email)
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
                                Text("Email".localized)
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
                Section("Professional Details".localized) {
                    if isEditing {
                        TextField("Company".localized, text: Binding(
                            get: { contact.company ?? "" },
                            set: { contact.company = $0.isEmpty ? nil : $0 }
                        ))
                        TextField("Contact source edit placeholder".localized, text: Binding(
                            get: { contact.contactSource ?? "" },
                            set: { contact.contactSource = $0.isEmpty ? nil : $0 }
                        ))
                        TextField("Website".localized, text: Binding(
                            get: { contact.website ?? "" },
                            set: { contact.website = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        TextField("Address".localized, text: Binding(
                            get: { contact.address ?? "" },
                            set: { contact.address = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .lineLimit(2...4)
                    } else {
                        if let company = contact.company, !company.isEmpty {
                            LabeledContent("Company".localized, value: company)
                        }
                        
                        if let contactSource = contact.contactSource, !contactSource.isEmpty {
                            LabeledContent("Contact Source".localized, value: contactSource)
                        }
                        
                        if let website = contact.website, !website.isEmpty {
                            Button {
                                openWebsite(website)
                            } label: {
                                HStack {
                                    Text("Website".localized)
                                    Spacer()
                                    Text(website)
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if let address = contact.address, !address.isEmpty {
                            LabeledContent("Address".localized, value: address)
                        }
                    }
                }
            }
            
            // Notes
            Section("Notes & Description".localized) {
                if isEditing {
                    TextField("Contact notes edit placeholder".localized, text: Binding(
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
                        Text("No notes added".localized)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            
            // Quick Actions (only in view mode)
            if !isEditing && !phoneNumbers.isEmpty {
                Section("Quick Actions".localized) {
                    // Show buttons for first number if multiple numbers exist
                    if let primaryPhone = phoneNumbers.first {
                        Button {
                            call(phone: primaryPhone)
                        } label: {
                            Label(phoneNumbers.count > 1 ? "Call (Primary)".localized : "Call".localized, systemImage: "phone")
                        }
                        
                        Button {
                            sendSMS(to: primaryPhone)
                        } label: {
                            Label(phoneNumbers.count > 1 ? "Send SMS (Primary)".localized : "Send SMS".localized, systemImage: "message")
                        }
                    }
                    
                    if !contact.email.isEmpty {
                        Button {
                            sendEmail(to: contact.email)
                        } label: {
                            Label("Send Email".localized, systemImage: "envelope")
                        }
                    }
                }
                
                // Delete button
                if AppState.shared.hasEditPermission(for: .contacts) {
                    Section {
                        Button("Delete Contact".localized, role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Contact".localized : contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Edit/Save button
            if AppState.shared.hasEditPermission(for: .contacts) {
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save".localized) {
                            saveChanges()
                        }
                    } else {
                        Button("Edit".localized) {
                            isEditing = true
                        }
                    }
                }
            }
            
            // Cancel button (only in edit mode)
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
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
        .alert("Delete Contact?".localized, isPresented: $showingDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Delete".localized, role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("Delete contact confirmation".localized)
        }
        .alert("Add Phone Number".localized, isPresented: $showingAddPhone) {
            TextField("Phone number".localized, text: $newPhoneNumber)
                .keyboardType(.phonePad)
            
            Button("Cancel".localized, role: .cancel) {
                newPhoneNumber = ""
            }
            
            Button("Add".localized) {
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
                        Text(phoneNumbers.count > 1 ? String(format: "Phone %d".localized, index + 1) : "Phone".localized)
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
                Text("Phone Numbers".localized)
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
                Text("No phone numbers".localized)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(phoneNumbers.enumerated()), id: \.offset) { index, phoneNumber in
                    HStack {
                        TextField(String(format: "Phone %d".localized, index + 1), text: Binding(
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
