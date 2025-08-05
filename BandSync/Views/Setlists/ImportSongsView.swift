//
//  ImportSongsView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 09.05.2025.
//

import SwiftUI

struct ImportSongsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = SetlistService.shared
    @Binding var selectedSongs: [Song]
    let useTimings: Bool
    let onImport: () -> Void
    
    @State private var selectedSetlist: Setlist?
    @State private var selectedIndices: [Int] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if service.setlists.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header с иконкой
                            headerView
                            
                            // Выбор сетлиста
                            setlistSelectorCard
                            
                            // Список песен для импорта
                            if let setlist = selectedSetlist {
                                songsSelectionCard(setlist: setlist)
                                
                                // Кнопки действий
                                actionButtonsCard
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Import Songs", comment: "Navigation title for importing songs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    importButton
                }
            }
            .onAppear {
                if service.setlists.isEmpty {
                    if let groupId = AppState.shared.user?.groupId {
                        service.fetchSetlists(for: groupId)
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .indigo.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("Import Songs", comment: "Header title for importing songs"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("Choose songs from setlists", comment: "Header description for importing songs"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.secondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .gray.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text(NSLocalizedString("No setlists available", comment: "Empty state title when no setlists"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("Create setlists first", comment: "Empty state description when no setlists"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Setlist Selector Card
    private var setlistSelectorCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(NSLocalizedString("Choose setlist", comment: "Section header for choosing setlist"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Source setlist", comment: "Label for source setlist selection"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Picker("Setlist", selection: $selectedSetlist) {
                        Text(NSLocalizedString("Select setlist", comment: "Placeholder for setlist picker")).tag(nil as Setlist?)
                        ForEach(service.setlists) { setlist in
                            Text(setlist.name).tag(setlist as Setlist?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onChange(of: selectedSetlist) {
                        selectedIndices = []
                    }
                }
                
                if let setlist = selectedSetlist {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Setlist info", comment: "Label for setlist information"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(setlist.songs.count) songs • \(setlist.formattedTotalDuration)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Songs Selection Card
    private func songsSelectionCard(setlist: Setlist) -> some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Select Songs (%d/%d)", comment: "Section header for selecting songs with counts").replacingOccurrences(of: "%d", with: "\(selectedIndices.count)").replacingOccurrences(of: "%d", with: "\(setlist.songs.count)"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Progress indicator
                if !selectedIndices.isEmpty {
                    Text("\(selectedIndices.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(setlist.songs.indices, id: \.self) { index in
                    let song = setlist.songs[index]
                    let isSelected = selectedIndices.contains(index)
                    
                    Button(action: {
                        toggleSongSelection(index)
                    }) {
                        HStack(spacing: 12) {
                            // Checkbox
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.purple : Color(.systemGray5))
                                    .frame(width: 24, height: 24)
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            // Номер песни
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.secondary)
                                .cornerRadius(10)
                            
                            // Информация о песне
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text("\(song.formattedDuration) • \(song.bpm) BPM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if isSelected {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons Card
    private var actionButtonsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(NSLocalizedString("Actions", comment: "Section header for actions"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button(action: {
                    if let setlist = selectedSetlist {
                        if selectedIndices.count == setlist.songs.count {
                            selectedIndices = []
                        } else {
                            selectedIndices = Array(0..<setlist.songs.count)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: selectedIndices.count == selectedSetlist?.songs.count ? "checkmark.square.fill" : "square")
                            .foregroundColor(.orange)
                        
                        Text(selectedIndices.count == selectedSetlist?.songs.count ? NSLocalizedString("Deselect All", comment: "Button to deselect all songs") : NSLocalizedString("Select All", comment: "Button to select all songs"))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if let setlist = selectedSetlist {
                            Text("\(setlist.songs.count) " + String.ukrainianSongsPlural(count: setlist.songs.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(selectedSetlist == nil)
                
                if !selectedIndices.isEmpty {
                    HStack {
                        Text(NSLocalizedString("Selected for import", comment: "Label for selected songs count"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(selectedIndices.count) " + String.ukrainianSongsPlural(count: selectedIndices.count))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Buttons
    private var cancelButton: some View {
        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
            dismiss()
        }
        .font(.body)
        .foregroundColor(.secondary)
    }
    
    private var importButton: some View {
        Button(NSLocalizedString("Import", comment: "Import button")) {
            importSelectedSongs()
        }
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.indigo, Color.cyan]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 2)
        .disabled(selectedIndices.isEmpty)
        .opacity(selectedIndices.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    // Toggle song selection
    private func toggleSongSelection(_ index: Int) {
        if let position = selectedIndices.firstIndex(of: index) {
            selectedIndices.remove(at: position)
        } else {
            selectedIndices.append(index)
        }
    }
    
    // Import selected songs
    private func importSelectedSongs() {
        guard let setlist = selectedSetlist else { return }
        
        // Create copies of selected songs
        let songsToAdd = selectedIndices.sorted().map { index -> Song in
            var song = setlist.songs[index]
            // Create a new ID for the song to make it unique
            song.id = UUID().uuidString
            // Reset start time so it can be recalculated
            song.startTime = nil
            return song
        }
        
        // Add songs to selected setlist
        selectedSongs.append(contentsOf: songsToAdd)
        
        // Call import handler to recalculate timings
        onImport()
        
        // Close window
        dismiss()
    }
}
