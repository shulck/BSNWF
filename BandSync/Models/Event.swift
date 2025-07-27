//
//  Event.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    
    var title: String
    var date: Date
    var type: EventType
    var status: EventStatus
    var location: String?
    
    var organizerName: String?
    var organizerEmail: String?
    var organizerPhone: String?
    
    var coordinatorName: String?
    var coordinatorEmail: String?
    var coordinatorPhone: String?
    
    var hotelName: String?
    var hotelAddress: String?
    var hotelCheckIn: Date?
    var hotelCheckOut: Date?
    
    var hotelBreakfastIncluded: Bool?
    
    var fee: Double?
    var currency: String?
    
    var notes: String?
    var schedule: [String]?
    
    var setlistId: String?
    var groupId: String
    var isPersonal: Bool
    var createdBy: String?
    
    var rating: Int?
    var ratingComment: String?
    
    enum CodingKeys: String, CodingKey {
        case title, date, type, status, location
        case organizerName, organizerEmail, organizerPhone
        case coordinatorName, coordinatorEmail, coordinatorPhone
        case hotelName, hotelAddress, hotelCheckIn, hotelCheckOut
        case hotelBreakfastIncluded
        case fee, currency, notes, schedule
        case setlistId, groupId, isPersonal, createdBy
        case rating, ratingComment
    }
}
