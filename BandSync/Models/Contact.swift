//
//  Contact.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseFirestore

struct Contact: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var phone: String
    var role: String
    var groupId: String
    var eventTag: String?
    var eventType: String?
    
    var company: String?
    var contactSource: String?
    var description: String?
    var website: String?
    var address: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case role
        case groupId
        case eventTag
        case eventType
        case company
        case contactSource
        case description
        case website
        case address
        case createdAt
        case updatedAt
    }
    
    init(name: String,
         email: String,
         phone: String,
         role: String,
         groupId: String,
         eventTag: String? = nil,
         eventType: String? = nil,
         company: String? = nil,
         contactSource: String? = nil,
         description: String? = nil,
         website: String? = nil,
         address: String? = nil) {
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.groupId = groupId
        self.eventTag = eventTag
        self.eventType = eventType
        self.company = company
        self.contactSource = contactSource
        self.description = description
        self.website = website
        self.address = address
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    var fullCompanyInfo: String {
        if let company = company, !company.isEmpty {
            return "\(role) at \(company)"
        } else {
            return role
        }
    }
    
    var shortInfo: String {
        var info = [String]()
        
        if let company = company, !company.isEmpty {
            info.append(company)
        }
        
        if let source = contactSource, !source.isEmpty {
            info.append("via \(source)")
        }
        
        return info.joined(separator: " • ")
    }
    
    var fullAddress: String {
        return address ?? ""
    }
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !groupId.isEmpty
    }
    
    var hasContactInfo: Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
