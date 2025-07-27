//
//  DocumentModels.swift
//  BandSync
//
//  Created for Google Drive integration
//  Date: 16.06.2025
//

import Foundation

// MARK: - Document Types

enum DocumentType: String, CaseIterable, Codable {
    case technicalRider = "technical_rider"
    case hospitalityRider = "hospitality_rider"
    case stagePlot = "stage_plot"
    case inputList = "input_list"
    case contract = "contract"
    case pressKit = "press_kit"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .technicalRider: return "Technical Rider"
        case .hospitalityRider: return "Hospitality Rider"
        case .stagePlot: return "Stage Plot"
        case .inputList: return "Input List"
        case .contract: return "Contract"
        case .pressKit: return "Press Kit"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .technicalRider: return "music.mic"
        case .hospitalityRider: return "house"
        case .stagePlot: return "rectangle.3.group"
        case .inputList: return "list.bullet"
        case .contract: return "doc.text"
        case .pressKit: return "folder.badge.plus"
        case .other: return "doc"
        }
    }
}

enum VenueType: String, CaseIterable, Codable {
    case club = "club"
    case festival = "festival"
    case theater = "theater"
    case arena = "arena"
    case outdoor = "outdoor"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .club: return "Club"
        case .festival: return "Festival"
        case .theater: return "Theater"
        case .arena: return "Arena"
        case .outdoor: return "Outdoor Event"
        case .other: return "Other"
        }
    }
}

// MARK: - Document Model

struct Document: Codable, Identifiable {
    let id: String
    var name: String
    let type: DocumentType
    var venueType: VenueType?
    var description: String?
    
    // Google Drive integration
    let googleDriveFileId: String?
    let googleDriveUrl: String?
    let mimeType: String
    
    // Metadata
    let groupId: String
    let createdBy: String
    let createdAt: Date
    var updatedAt: Date
    var version: Int
    
    // Event association
    let eventId: String?
    let folderId: String?
    
    // Access control
    let isTemplate: Bool
    let isPublic: Bool
    
    // File info
    let fileSize: Int64?
    let lastModified: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: DocumentType,
        venueType: VenueType? = nil,
        description: String? = nil,
        googleDriveFileId: String? = nil,
        googleDriveUrl: String? = nil,
        mimeType: String,
        groupId: String,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        version: Int = 1,
        eventId: String? = nil,
        folderId: String? = nil,
        isTemplate: Bool = false,
        isPublic: Bool = false,
        fileSize: Int64? = nil,
        lastModified: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.venueType = venueType
        self.description = description
        self.googleDriveFileId = googleDriveFileId
        self.googleDriveUrl = googleDriveUrl
        self.mimeType = mimeType
        self.groupId = groupId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
        self.eventId = eventId
        self.folderId = folderId
        self.isTemplate = isTemplate
        self.isPublic = isPublic
        self.fileSize = fileSize
        self.lastModified = lastModified
    }
}

// MARK: - Document Folder Structure

struct DocumentFolder: Codable, Identifiable {
    let id: String
    let name: String
    let type: DocumentType?
    let eventId: String?
    let groupId: String
    let parentFolderId: String?
    var googleDriveFolderId: String?
    let createdAt: Date
    let isSystemFolder: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: DocumentType? = nil,
        eventId: String? = nil,
        groupId: String,
        parentFolderId: String? = nil,
        googleDriveFolderId: String? = nil,
        createdAt: Date = Date(),
        isSystemFolder: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.eventId = eventId
        self.groupId = groupId
        self.parentFolderId = parentFolderId
        self.googleDriveFolderId = googleDriveFolderId
        self.createdAt = createdAt
        self.isSystemFolder = isSystemFolder
    }
}

// MARK: - Document Permissions

struct DocumentPermissions: Codable {
    let canView: Bool
    let canEdit: Bool
    let canDelete: Bool
    let canShare: Bool
    let canCreateFolders: Bool
    let canUpload: Bool
    
    init(
        canView: Bool = false,
        canEdit: Bool = false,
        canDelete: Bool = false,
        canShare: Bool = false,
        canCreateFolders: Bool = false,
        canUpload: Bool = false
    ) {
        self.canView = canView
        self.canEdit = canEdit
        self.canDelete = canDelete
        self.canShare = canShare
        self.canCreateFolders = canCreateFolders
        self.canUpload = canUpload
    }
    
    static let adminPermissions = DocumentPermissions(
        canView: true,
        canEdit: true,
        canDelete: true,
        canShare: true,
        canCreateFolders: true,
        canUpload: true
    )
    
    static let managerPermissions = DocumentPermissions(
        canView: true,
        canEdit: true,
        canDelete: true,  // Manager now has delete permissions for documents
        canShare: true,
        canCreateFolders: true,
        canUpload: true
    )
    
    static let memberPermissions = DocumentPermissions(
        canView: true,
        canEdit: false,
        canDelete: false,
        canShare: false,
        canCreateFolders: false,
        canUpload: false
    )
}

// MARK: - Document Template

struct DocumentTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let type: DocumentType
    let venueType: VenueType?
    let description: String
    let templateContent: String? // For text-based templates
    let googleDriveTemplateId: String?
    let isSystemTemplate: Bool
    let groupId: String?
    let createdBy: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        type: DocumentType,
        venueType: VenueType? = nil,
        description: String,
        templateContent: String? = nil,
        googleDriveTemplateId: String? = nil,
        isSystemTemplate: Bool = false,
        groupId: String? = nil,
        createdBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.venueType = venueType
        self.description = description
        self.templateContent = templateContent
        self.googleDriveTemplateId = googleDriveTemplateId
        self.isSystemTemplate = isSystemTemplate
        self.groupId = groupId
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

// MARK: - Extensions

extension Document {
    var formattedFileSize: String {
        guard let fileSize = fileSize else { return "Unknown size" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var isGoogleDriveDocument: Bool {
        return googleDriveFileId != nil
    }
    
    var canBeEdited: Bool {
        return mimeType.contains("document") || 
               mimeType.contains("spreadsheet") || 
               mimeType.contains("presentation")
    }
}

extension DocumentType {
    static var riderTypes: [DocumentType] {
        return [.technicalRider, .hospitalityRider, .stagePlot, .inputList]
    }
    
    static var contractTypes: [DocumentType] {
        return [.contract]
    }
    
    static var marketingTypes: [DocumentType] {
        return [.pressKit]
    }
}
