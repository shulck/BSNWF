//
//  FanAddress.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 31.07.2025.
//


//
//  FanAddressModels.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 01.08.2025.
//

import Foundation

struct FanAddress {
    let country: String
    let countryName: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let state: String
    let zipCode: String
    
    var fullAddress: String {
        var components: [String] = []
        
        if !addressLine1.isEmpty {
            components.append(addressLine1)
        }
        
        if !addressLine2.isEmpty {
            components.append(addressLine2)
        }
        
        return components.joined(separator: ", ")
    }
    
    var cityStateCountry: String {
        var components: [String] = []
        
        if !city.isEmpty {
            components.append(city)
        }
        
        if !state.isEmpty {
            components.append(state)
        }
        
        if !countryName.isEmpty {
            components.append(countryName)
        }
        
        return components.joined(separator: ", ")
    }
    
    var isEmpty: Bool {
        return addressLine1.isEmpty && city.isEmpty && zipCode.isEmpty
    }
    
    var isComplete: Bool {
        return !addressLine1.isEmpty && !city.isEmpty && !countryName.isEmpty
    }
    
    var formattedAddress: String {
        var lines: [String] = []
        
        if !addressLine1.isEmpty {
            lines.append(addressLine1)
        }
        
        if !addressLine2.isEmpty {
            lines.append(addressLine2)
        }
        
        var cityLine = ""
        if !city.isEmpty {
            cityLine = city
        }
        
        if !state.isEmpty {
            cityLine += cityLine.isEmpty ? state : ", \(state)"
        }
        
        if !zipCode.isEmpty {
            cityLine += cityLine.isEmpty ? zipCode : " \(zipCode)"
        }
        
        if !cityLine.isEmpty {
            lines.append(cityLine)
        }
        
        if !countryName.isEmpty {
            lines.append(countryName)
        }
        
        return lines.joined(separator: "\n")
    }
}