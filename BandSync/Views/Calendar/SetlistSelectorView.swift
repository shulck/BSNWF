//
//  SetlistSelectorView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct SetlistSelectorView: View {
    @StateObject private var setlistService = SetlistService.shared
    @Binding var selectedSetlistId: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // No setlist option
                Button {
                    selectedSetlistId = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No setlist".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedSetlistId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // List of all available setlists
                ForEach(setlistService.setlists) { setlist in
                    Button {
                        selectedSetlistId = setlist.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(setlist.name)
                                    .foregroundColor(.primary)
                                
                                Text("\(setlist.songs.count) " + "songs".localized + " • \(setlist.formattedTotalDuration)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedSetlistId == setlist.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if setlistService.setlists.isEmpty {
                    Text("No available setlists".localized)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle("Select setlist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let groupId = AppState.shared.user?.groupId {
                    setlistService.fetchSetlists(for: groupId)
                }
            }
        }
    }
}
