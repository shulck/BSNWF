//
//  TimingDetailView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 09.05.2025.
//

import SwiftUI

struct TimingDetailView: View {
    let setlist: Setlist
    @Environment(\.dismiss) var dismiss
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
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
                        
                        // Concert Information Card
                        if let concertDate = setlist.concertDate {
                            concertInfoCard(concertDate: concertDate)
                        }
                        
                        // Songs Timeline Card
                        songsTimelineCard
                        
                        // Summary Card
                        summaryCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(NSLocalizedString("Setlist Timing", comment: "Navigation title for setlist timing view"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
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
                            gradient: Gradient(colors: [Color.cyan, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .cyan.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "clock")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("Concert timeline", comment: "Header for concert timeline section"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("Track setlist timing", comment: "Description for concert timeline section"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Concert Info Card
    private func concertInfoCard(concertDate: Date) -> some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(NSLocalizedString("Concert information", comment: "Section header for concert information"))
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
                // Start Date and Time
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Start date time", comment: "Label for concert start date and time"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate(concertDate))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
                
                // Estimated End Time
                if let estimatedEndTime = calculateEstimatedEndTime(from: concertDate) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Estimated end time", comment: "Label for estimated concert end time"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(timeFormatter.string(from: estimatedEndTime))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.blue)
                                .font(.title3)
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
    
    // MARK: - Songs Timeline Card
    private var songsTimelineCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Song Timeline", comment: "Section header for song timeline") + " (\(setlist.songs.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                ForEach(setlist.songs.indices, id: \.self) { index in
                    let song = setlist.songs[index]
                    
                    SongTimelineRowView(
                        song: song,
                        index: index,
                        timeFormatter: timeFormatter,
                        isLast: index == setlist.songs.count - 1
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
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(NSLocalizedString("Timeline summary", comment: "Section header for timeline summary"))
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
                // Total Songs
                SummaryRowView(
                    icon: "music.note",
                    title: NSLocalizedString("Total Songs", comment: "Title for total songs statistic"),
                    value: "\(setlist.songs.count) " + String.ukrainianSongsPlural(count: setlist.songs.count),
                    color: .purple
                )
                
                // Total Duration
                SummaryRowView(
                    icon: "clock",
                    title: NSLocalizedString("Total Duration", comment: "Title for total duration statistic"),
                    value: setlist.formattedTotalDuration,
                    color: .orange
                )
                
                // Average Song Length
                SummaryRowView(
                    icon: "timer",
                    title: NSLocalizedString("Average Song Length", comment: "Title for average song length statistic"),
                    value: averageSongLength,
                    color: .blue
                )
                
                // Shortest Song
                if let shortestSong = setlist.songs.min(by: { $0.totalSeconds < $1.totalSeconds }) {
                    SummaryRowView(
                        icon: "backward",
                        title: NSLocalizedString("Shortest Song", comment: "Title for shortest song statistic"),
                        value: "\(shortestSong.title) (\(shortestSong.formattedDuration))",
                        color: .green
                    )
                }
                
                // Longest Song
                if let longestSong = setlist.songs.max(by: { $0.totalSeconds < $1.totalSeconds }) {
                    SummaryRowView(
                        icon: "forward",
                        title: NSLocalizedString("Longest Song", comment: "Title for longest song statistic"),
                        value: "\(longestSong.title) (\(longestSong.formattedDuration))",
                        color: .red
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
            dismiss()
        }
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.cyan, Color.blue]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .cyan.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func calculateEstimatedEndTime(from startDate: Date) -> Date? {
        let totalSeconds = setlist.songs.reduce(0) { $0 + $1.totalSeconds }
        return Calendar.current.date(byAdding: .second, value: totalSeconds, to: startDate)
    }
    
    private var averageSongLength: String {
        guard !setlist.songs.isEmpty else { return "0:00" }
        
        let totalSeconds = setlist.songs.reduce(0) { $0 + $1.totalSeconds }
        let averageSeconds = totalSeconds / setlist.songs.count
        let minutes = averageSeconds / 60
        let seconds = averageSeconds % 60
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Song Timeline Row View
struct SongTimelineRowView: View {
    let song: Song
    let index: Int
    let timeFormatter: DateFormatter
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Circle with number
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
                
                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Song information
            VStack(alignment: .leading, spacing: 8) {
                // Song title
                Text(song.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Song details
                HStack(spacing: 12) {
                    Label(song.formattedDuration, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("\(song.bpm) BPM", systemImage: "metronome")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if let key = song.key, !key.isEmpty {
                        Label(key, systemImage: "music.quarternote.3")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Start time
                if let startTime = song.startTime {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("Starts at \(timeFormatter.string(from: startTime))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.bottom, isLast ? 0 : 8)
    }
}

// MARK: - Summary Row View
struct SummaryRowView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}
