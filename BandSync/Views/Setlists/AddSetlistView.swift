//
//  AddSetlistView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct AddSetlistView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var songs: [Song] = []
    @State private var newTitle: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    @State private var bpm: String = ""
    @State private var key: String = "" // ADDED: key field
    @StateObject private var service = SetlistService.shared
    
    // Concert timing
    @State private var useTimings: Bool = false
    @State private var concertDate = Date()
    @State private var concertEndDate = Date(timeIntervalSinceNow: 7200) // Default +2 hours
    @State private var concertLengthHours: Int = 2
    @State private var concertLengthMinutes: Int = 0
    
    @State private var showImportSongs: Bool = false
    @State private var autoCreateSongs: Bool = false
    
    // State for song editing
    @State private var editingSongIndex: Int? = nil
    @State private var showEditSong = false
    
    // Sample song durations for auto-creation
    private let sampleSongDurations = [
        (3, 30), // 3 min 30 sec
        (4, 0),  // 4 min
        (3, 45), // 3 min 45 sec
        (5, 10), // 5 min 10 sec
        (3, 20), // 3 min 20 sec
        (4, 15)  // 4 min 15 sec
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header с иконкой
                    headerView
                    
                    // Основная информация о сетлисте
                    setlistInfoCard
                    
                    // Настройки концерта
                    if useTimings {
                        concertTimingCard
                    }
                    
                    // Автосоздание песен
                    if useTimings && autoCreateSongs && songs.count > 0 {
                        autoCreatedSongsCard
                    }
                    
                    // Add songs manually
                    manualSongAddCard
                    
                    // Список добавленных песен
                    if !songs.isEmpty {
                        songsListCard
                        summaryCard
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationTitle(NSLocalizedString("Create Setlist", comment: "Navigation title for creating setlist"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showImportSongs) {
                ImportSongsView(selectedSongs: $songs, useTimings: useTimings) {
                    recalculateTimings()
                }
            }
            .sheet(isPresented: $showEditSong, onDismiss: {
                editingSongIndex = nil
                recalculateTimings()
            }) {
                if let index = editingSongIndex, index < songs.count {
                    EditSongView(song: Binding(
                        get: { songs[index] },
                        set: { songs[index] = $0 }
                    ))
                }
            }
            .onChange(of: concertLengthHours) { updateConcertEndDate() }
            .onChange(of: concertLengthMinutes) { updateConcertEndDate() }
            .onChange(of: concertDate) { updateConcertEndDate() }
            .onAppear {
                if let groupId = AppState.shared.user?.groupId {
                    service.fetchSetlists(for: groupId)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(NSLocalizedString("Create New Setlist", comment: "Header title for creating new setlist"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Setlist Info Card
    private var setlistInfoCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(NSLocalizedString("Setlist Information", comment: "Section header for setlist information"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Поля ввода
            VStack(spacing: 16) {
                // Название сетлиста
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Setlist Name", comment: "Label for setlist name field"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField(NSLocalizedString("Enter setlist name", comment: "Placeholder for setlist name field"), text: $name)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Toggle для времени концерта
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Concert Timing", comment: "Label for concert timing toggle"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(NSLocalizedString("Plan your setlist with specific timing", comment: "Description for concert timing feature"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $useTimings)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Concert Timing Card
    private var concertTimingCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(NSLocalizedString("Concert Settings", comment: "Section header for concert settings"))
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
                // Дата и время концерта
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Concert Start", comment: "Label for concert start time"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    DatePicker(NSLocalizedString("Concert Start", comment: "Date picker label for concert start"), selection: $concertDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Продолжительность концерта
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Concert Duration", comment: "Label for concert duration"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Hours", comment: "Label for hours"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $concertLengthHours) {
                                ForEach(0..<6, id: \.self) { hour in
                                    Text("\(hour) " + NSLocalizedString("h", comment: "Hours abbreviation")).tag(hour)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Minutes", comment: "Label for minutes"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $concertLengthMinutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    if minute % 5 == 0 {
                                        Text("\(minute) " + NSLocalizedString("min", comment: "Minutes abbreviation")).tag(minute)
                                    }
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                }
                
                // Кнопка автосоздания
                Button(NSLocalizedString("Auto-create songs for concert", comment: "Button to auto-create songs for concert")) {
                    autoCreateSongsForConcert()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(10)
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Auto Created Songs Card
    private var autoCreatedSongsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Auto-created Songs", comment: "Section header for auto-created songs"))
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
                HStack {
                    Text(NSLocalizedString("Total songs:", comment: "Label for total songs count"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(songs.count) " + String.ukrainianSongsPlural(count: songs.count))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Text(NSLocalizedString("Total Duration:", comment: "Label for total duration"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedTotalDuration)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Button(NSLocalizedString("Clear and recreate", comment: "Button to clear and recreate songs")) {
                    autoCreateSongsForConcert()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(8)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Manual Song Add Card (ОБНОВЛЕНО)
    private var manualSongAddCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(NSLocalizedString("Add Songs", comment: "Section header for adding songs"))
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
                // Название песни
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Song Name", comment: "Label for song name field"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField(NSLocalizedString("Enter song name", comment: "Placeholder for song name field"), text: $newTitle)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Продолжительность
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Duration", comment: "Label for song duration"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Min", comment: "Minutes abbreviation"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("0", text: $minutes)
                                .keyboardType(.numberPad)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Text(":")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                        
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Sec", comment: "Seconds abbreviation"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("00", text: $seconds)
                                .keyboardType(.numberPad)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                }
                
                // BPM и Тональность
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("BPM", comment: "BPM label"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextField("120", text: $bpm)
                            .keyboardType(.numberPad)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Key (Optional)", comment: "Label for musical key field"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("C, Am, etc.", comment: "Placeholder for musical key field"), text: $key)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Кнопки действий
                HStack(spacing: 12) {
                    Button(NSLocalizedString("Add Song", comment: "Button to add song")) {
                        addSongManually()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                    .disabled(newTitle.isEmpty || (minutes.isEmpty && seconds.isEmpty) || bpm.isEmpty)
                    .opacity((newTitle.isEmpty || (minutes.isEmpty && seconds.isEmpty) || bpm.isEmpty) ? 0.6 : 1.0)
                    
                    Button(NSLocalizedString("Import Songs", comment: "Button to import songs")) {
                        showImportSongs = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Songs List Card (ОБНОВЛЕНО для отображения тональности)
    private var songsListCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Songs in Setlist (\(songs.count))")
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
                ForEach(songs.indices, id: \.self) { index in
                    let song = songs[index]
                    
                    HStack(spacing: 12) {
                        // Номер песни
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .cornerRadius(12)
                        
                        // Информация о песне
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Text(song.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("• \(song.bpm) BPM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let key = song.key, !key.isEmpty {
                                    Text("• \(key)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if useTimings, let startTime = song.startTime {
                                    Text("• Start: \(timeFormatter.string(from: startTime))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Кнопка редактирования
                        Button(action: {
                            editingSongIndex = index
                            showEditSong = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            songs.remove(at: index)
                            recalculateTimings()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Summary", comment: "Section header for summary"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                Text(NSLocalizedString("Total Duration", comment: "Label for total duration in summary"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedTotalDuration)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
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
    
    private var saveButton: some View {
        Button(NSLocalizedString("Save", comment: "Save button")) {
            saveSetlist()
        }
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.blue)
        .cornerRadius(20)
        .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
        .disabled(name.isEmpty || songs.isEmpty)
        .opacity((name.isEmpty || songs.isEmpty) ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    // Time formatter
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    // Formatted total duration
    private var formattedTotalDuration: String {
        let total = songs.reduce(0) { $0 + $1.totalSeconds }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // Update concert end date
    private func updateConcertEndDate() {
        let totalMinutes = concertLengthHours * 60 + concertLengthMinutes
        concertEndDate = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: concertDate) ?? concertDate
    }
    
    // Automatically create songs for concert
    private func autoCreateSongsForConcert() {
        songs = []
        autoCreateSongs = true
        
        // Collect existing songs from current setlists
        var existingSongs: [Song] = []
        for setlist in service.setlists {
            for song in setlist.songs {
                if !existingSongs.contains(where: { $0.title == song.title }) {
                    existingSongs.append(song)
                }
            }
        }
        
        // Total concert duration in seconds
        let totalConcertSeconds = concertLengthHours * 3600 + concertLengthMinutes * 60
        
        // Break duration (15% of total time)
        let breakDurationSeconds = Int(Double(totalConcertSeconds) * 0.15)
        
        // Remaining time for songs
        let availableSongTimeSeconds = totalConcertSeconds - breakDurationSeconds
        
        var currentTotalDuration = 0
        
        // If no existing songs, use templates
        if existingSongs.isEmpty {
            var songCounter = 1
            
            while currentTotalDuration < availableSongTimeSeconds {
                // Randomly select a duration from examples
                let randomIndex = Int.random(in: 0..<sampleSongDurations.count)
                let (min, sec) = sampleSongDurations[randomIndex]
                let songDuration = min * 60 + sec
                
                // If adding this song exceeds available time, exit
                if currentTotalDuration + songDuration > availableSongTimeSeconds {
                    break
                }
                
                // Create song with random BPM
                let randomBPM = Int.random(in: 90...160)
                let song = Song(
                    title: "Song \(songCounter)",
                    durationMinutes: min,
                    durationSeconds: sec,
                    bpm: randomBPM
                )
                
                songs.append(song)
                currentTotalDuration += songDuration
                songCounter += 1
            }
        } else {
            // Use existing songs
            let shuffledSongs = existingSongs.shuffled()
            var index = 0
            
            while currentTotalDuration < availableSongTimeSeconds && index < shuffledSongs.count {
                let song = shuffledSongs[index]
                
                // If adding this song exceeds available time, try the next one
                if currentTotalDuration + song.totalSeconds > availableSongTimeSeconds && index < shuffledSongs.count - 1 {
                    index += 1
                    continue
                }
                
                // Clone song with new ID
                var newSong = song
                newSong.id = UUID().uuidString
                newSong.startTime = nil
                
                songs.append(newSong)
                currentTotalDuration += newSong.totalSeconds
                index += 1
                
                // If we've gone through all songs but still haven't filled the time, start over
                if index >= shuffledSongs.count && currentTotalDuration < availableSongTimeSeconds {
                    index = 0
                }
            }
        }
        
        // Recalculate timings for all songs
        recalculateTimings()
    }
    
    // Add song manually (ОБНОВЛЕНО с тональностью)
    private func addSongManually() {
        guard let min = Int(minutes), let sec = Int(seconds), let bpmVal = Int(bpm), !newTitle.isEmpty else { return }
        
        let song = Song(
            title: newTitle,
            durationMinutes: min,
            durationSeconds: sec,
            bpm: bpmVal,
            key: key.isEmpty ? nil : key // Добавляем тональность
        )
        
        songs.append(song)
        newTitle = ""
        minutes = ""
        seconds = ""
        bpm = ""
        key = "" // Очищаем поле тональности
        
        recalculateTimings()
    }
    
    // Recalculate timings for all songs
    private func recalculateTimings() {
        if !songs.isEmpty && useTimings {
            // Create a full copy of the array
            var updatedSongs = songs
            var currentTime = concertDate
            
            // Update timings for all songs
            for i in 0..<updatedSongs.count {
                updatedSongs[i].startTime = currentTime
                currentTime = Date(timeInterval: Double(updatedSongs[i].totalSeconds), since: currentTime)
            }
            
            // Assign the updated array
            songs = updatedSongs
        }
    }
    
    // Save setlist
    private func saveSetlist() {
        guard let uid = AppState.shared.user?.id,
              let groupId = AppState.shared.user?.groupId,
              !name.isEmpty, !songs.isEmpty
        else { return }
        
        if useTimings {
            recalculateTimings()
        }

        let setlist = Setlist(
            name: name,
            userId: uid,
            groupId: groupId,
            isShared: true,
            songs: songs,
            concertDate: useTimings ? concertDate : nil
        )

        SetlistService.shared.addSetlist(setlist) { success in
            if success {
                dismiss()
            }
        }
    }
}
