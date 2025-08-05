//
//  TimingEditorView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 09.05.2025.
//

import SwiftUI

struct TimingEditorView: View {
    @Binding var songs: [Song]
    @Binding var concertDate: Date
    @Binding var hasEndTime: Bool
    @Binding var concertEndDate: Date
    let onTimingsChanged: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var editingSong: Int? = nil
    @State private var newStartTime: Date = Date()
    @State private var showAlertForBreaks: Bool = false
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    private var totalDuration: String {
        let seconds = songs.reduce(0) { $0 + $1.totalSeconds }
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header с иконкой
                        headerView
                        
                        // Concert Parameters Card
                        concertParametersCard
                        
                        // Setlist Timing Card
                        setlistTimingCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(NSLocalizedString("Edit Timing", comment: "Navigation title for timing editor"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .alert(NSLocalizedString("Add Breaks", comment: "Alert title for adding breaks"), isPresented: $showAlertForBreaks) {
                Button(NSLocalizedString("5 min between songs", comment: "Option to add 5 minute breaks")) { addBreaks(5) }
                Button(NSLocalizedString("10 min between songs", comment: "Option to add 10 minute breaks")) { addBreaks(10) }
                Button(NSLocalizedString("15 min between songs", comment: "Option to add 15 minute breaks")) { addBreaks(15) }
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("Select The Duration Of Breaks Between Songs", comment: "Alert message for selecting break duration"))
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
                            gradient: Gradient(colors: [Color.indigo, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .indigo.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("Timing Editor", comment: "Header for timing editor"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("Adjust Your Concert Schedule", comment: "Description for timing editor"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Concert Parameters Card
    private var concertParametersCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(NSLocalizedString("Concert Parameters", comment: "Section header for concert parameters"))
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
                // Concert Start
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Concert Start", comment: "Label for concert start time"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    DatePicker("Concert Start", selection: $concertDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onChange(of: concertDate) {
                            onTimingsChanged()
                        }
                }
                
                // Fix End Time Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Fixed End Time", comment: "Toggle label for fixed end time"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Set A Specific End Time For The Concert", comment: "Description for fixed end time toggle"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $hasEndTime)
                        .labelsHidden()
                        .onChange(of: hasEndTime) {
                            onTimingsChanged()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(hasEndTime ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                
                // Concert End (if enabled)
                if hasEndTime {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Concert End", comment: "Label for concert end time"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        DatePicker("Concert End", selection: $concertEndDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: concertEndDate) {
                                onTimingsChanged()
                            }
                    }
                    
                    // Add Breaks Button
                    Button(NSLocalizedString("Add Breaks Between Songs", comment: "Button to add breaks between songs")) {
                        showAlertForBreaks = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Setlist Timing Card
    private var setlistTimingCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Setlist Timing", comment: "Section header for setlist timing"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Duration badge
                Text(totalDuration)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(songs.indices, id: \.self) { index in
                    SongTimingRowView(
                        song: songs[index],
                        index: index,
                        editingSong: $editingSong,
                        newStartTime: $newStartTime,
                        songs: $songs,
                        timeFormatter: timeFormatter,
                        nextSong: index < songs.count - 1 ? songs[index + 1] : nil,
                        onTimingChanged: {
                            recalculateTimingsFromIndex(index + 1)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Done Button
    private var doneButton: some View {
        Button("Done") {
            onTimingsChanged()
            dismiss()
        }
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.indigo, Color.pink]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .indigo.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    // Recalculate timings starting from specified index
    private func recalculateTimingsFromIndex(_ startIndex: Int) {
        guard startIndex < songs.count else { return }
        
        var updatedSongs = songs
        var currentTime: Date
        if startIndex > 0, let previousSongStart = updatedSongs[startIndex - 1].startTime {
            // Start after previous song
            currentTime = Date(timeInterval: Double(updatedSongs[startIndex - 1].totalSeconds), since: previousSongStart)
        } else {
            // Or from the beginning of the concert, if this is the first song
            currentTime = concertDate
        }
        
        for i in startIndex..<updatedSongs.count {
            var song = updatedSongs[i]
            song.startTime = currentTime
            updatedSongs[i] = song
            
            currentTime = Date(timeInterval: Double(song.totalSeconds), since: currentTime)
        }
        
        songs = updatedSongs
    }
    
    // Add breaks between songs
    private func addBreaks(_ minutes: Int) {
        guard songs.count > 1 else { return }
        
        var updatedSongs = songs
        var currentTime = concertDate
        
        for i in 0..<updatedSongs.count {
            var song = updatedSongs[i]
            song.startTime = currentTime
            updatedSongs[i] = song
            
            // After each song (except the last one) add a break
            currentTime = Date(timeInterval: Double(song.totalSeconds), since: currentTime)
            if i < updatedSongs.count - 1 {
                currentTime = Date(timeInterval: Double(minutes * 60), since: currentTime)
            }
        }
        
        songs = updatedSongs
        
        // If total time exceeds concert time, adjust timing
        if hasEndTime && songs.count > 0 {
            let lastSong = updatedSongs.last!
            if let lastStart = lastSong.startTime {
                let currentEnd = Date(timeInterval: Double(lastSong.totalSeconds), since: lastStart)
                
                if currentEnd > concertEndDate {
                    // Adjust by removing breaks or compressing total time
                    distributeTimeBetweenSongsWithoutBreaks()
                }
            }
        }
    }
    
    // Distribute time evenly, without breaks
    private func distributeTimeBetweenSongsWithoutBreaks() {
        guard hasEndTime && !songs.isEmpty else { return }
        
        let totalSeconds = songs.reduce(0) { $0 + $1.totalSeconds }
        let availableTime = concertEndDate.timeIntervalSince(concertDate)
        
        var updatedSongs = songs
        
        // If total song duration exceeds available time,
        // proportionally compress time
        if Double(totalSeconds) > availableTime {
            let scaleFactor = availableTime / Double(totalSeconds)
            var currentTime = concertDate
            
            for i in 0..<updatedSongs.count {
                var song = updatedSongs[i]
                song.startTime = currentTime
                updatedSongs[i] = song
                
                let scaledDuration = Double(song.totalSeconds) * scaleFactor
                currentTime = Date(timeInterval: scaledDuration, since: currentTime)
            }
        } else {
            // Otherwise distribute songs evenly
            let timePerSong = availableTime / Double(updatedSongs.count)
            var currentTime = concertDate
            
            for i in 0..<updatedSongs.count {
                var song = updatedSongs[i]
                song.startTime = currentTime
                updatedSongs[i] = song
                
                currentTime = Date(timeInterval: timePerSong, since: currentTime)
            }
        }
        
        songs = updatedSongs
    }
    
    // Format time interval to min:sec
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Song Timing Row View
struct SongTimingRowView: View {
    let song: Song
    let index: Int
    @Binding var editingSong: Int?
    @Binding var newStartTime: Date
    @Binding var songs: [Song]
    let timeFormatter: DateFormatter
    let nextSong: Song?
    let onTimingChanged: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Song header
            HStack(spacing: 12) {
                // Song number
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(song.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Timing controls
            if let startTime = song.startTime {
                VStack(spacing: 8) {
                    if editingSong == index {
                        // Edit mode
                        HStack(spacing: 12) {
                            Text("New start time:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $newStartTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button("OK") {
                                // Apply new start time
                                var updatedSongs = songs
                                var songCopy = updatedSongs[index]
                                songCopy.startTime = newStartTime
                                updatedSongs[index] = songCopy
                                songs = updatedSongs
                                
                                // Recalculate timing for following songs
                                onTimingChanged()
                                
                                editingSong = nil
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    } else {
                        // Display mode
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Start: \(timeFormatter.string(from: startTime))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                editingSong = index
                                newStartTime = startTime
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // Break information
                        if let nextSong = nextSong, let nextStartTime = nextSong.startTime {
                            let breakInterval = nextStartTime.timeIntervalSince(Date(timeInterval: Double(song.totalSeconds), since: startTime))
                            
                            if breakInterval > 0 {
                                HStack {
                                    Image(systemName: "pause.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text("Break: \(formatTimeInterval(breakInterval))")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // Format time interval to min:sec
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
