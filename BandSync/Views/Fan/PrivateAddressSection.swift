//
//  PrivateAddressSection.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 01.08.2025.
//

import SwiftUI
import FirebaseFirestore

struct PrivateAddressSection: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var address: FanAddress?
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок с иконкой приватности
            HStack {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Contact Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Значок приватности
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Private")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            
            if isLoading {
                // Состояние загрузки
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading contact information...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(cardBackground)
                .cornerRadius(12)
                
            } else {
                VStack(spacing: 16) {
                    // Personal Information Section
                    if let user = appState.user {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section header
                            HStack(spacing: 8) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("Personal Details")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 8) {
                                if !user.name.isEmpty {
                                    ContactInfoRow(
                                        icon: "person.fill",
                                        title: "Full Name",
                                        value: user.name
                                    )
                                }
                                
                                if !user.email.isEmpty {
                                    ContactInfoRow(
                                        icon: "envelope.fill",
                                        title: "Email",
                                        value: user.email
                                    )
                                }
                                
                                if !user.phone.isEmpty {
                                    ContactInfoRow(
                                        icon: "phone.fill",
                                        title: "Phone",
                                        value: user.phone
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // Address Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Shipping Address")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        if let address = address, !address.isEmpty {
                            VStack(spacing: 8) {
                                if !address.addressLine1.isEmpty {
                                    ContactInfoRow(
                                        icon: "house.fill",
                                        title: "Street Address",
                                        value: address.fullAddress
                                    )
                                }
                                
                                if !address.city.isEmpty {
                                    ContactInfoRow(
                                        icon: "building.2.fill",
                                        title: "Location",
                                        value: address.cityStateCountry
                                    )
                                }
                                
                                if !address.zipCode.isEmpty {
                                    ContactInfoRow(
                                        icon: "number",
                                        title: "Postal Code",
                                        value: address.zipCode
                                    )
                                }
                                
                                // Status indicator
                                HStack(spacing: 8) {
                                    Image(systemName: address.isComplete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(address.isComplete ? .green : .orange)
                                        .font(.caption)
                                    
                                    Text(address.isComplete ? "Address complete" : "Incomplete address")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        } else {
                            // No address
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.slash")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text("No shipping address")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Add your address in profile settings for merchandise orders")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(cardBackground)
                    .cornerRadius(12)
                    
                    // Privacy notice
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("This information is private and only visible to you")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            loadAddress()
        }
    }
    
    private var cardBackground: some View {
        colorScheme == .dark ?
        Color(UIColor.secondarySystemGroupedBackground) :
        Color(.systemGray6)
    }
    
    private func loadAddress() {
        guard let user = appState.user else {
            isLoading = false
            return
        }
        
        db.collection("users").document(user.id)
            .collection("profile").document("address")
            .getDocument { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("Error loading address: \(error)")
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        return
                    }
                    
                    address = FanAddress(
                        country: data["country"] as? String ?? "",
                        countryName: data["countryName"] as? String ?? "",
                        addressLine1: data["addressLine1"] as? String ?? "",
                        addressLine2: data["addressLine2"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        state: data["state"] as? String ?? "",
                        zipCode: data["zipCode"] as? String ?? ""
                    )
                }
            }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 18)
                .font(.system(size: 12, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PrivateAddressSection()
        .environmentObject(AppState.shared)
        .padding()
        .background(Color(.systemGroupedBackground))
}
