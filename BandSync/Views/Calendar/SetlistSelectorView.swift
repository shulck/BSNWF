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
                        Text(NSLocalizedString("No setlist", comment: "Option to select no setlist"))
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
                                
                                Text(String(format: NSLocalizedString("%d songs • %@", comment: "Setlist songs count and duration format"), setlist.songs.count, setlist.formattedTotalDuration))
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
                    Text(NSLocalizedString("No available setlists", comment: "Message when no setlists are available"))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle(NSLocalizedString("Select setlist", comment: "Navigation title for setlist selector"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in setlist selector")) {
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
