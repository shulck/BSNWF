import SwiftUI
import os.log

struct EditSongView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var song: Song
    private let logger = Logger(subsystem: "com.bandsync.app", category: "EditSongView")
    
    // Local state for editing
    @State private var editedTitle: String
    @State private var editedDurationMinutes: Int
    @State private var editedDurationSeconds: Int
    @State private var editedBpm: Int
    @State private var editedKey: String
    
    // Initialize with copied values to prevent direct binding issues
    init(song: Binding<Song>) {
        self._song = song
        
        // Initialize local state variables with the current song values
        self._editedTitle = State(initialValue: song.wrappedValue.title)
        self._editedDurationMinutes = State(initialValue: song.wrappedValue.durationMinutes)
        self._editedDurationSeconds = State(initialValue: song.wrappedValue.durationSeconds)
        self._editedBpm = State(initialValue: song.wrappedValue.bpm)
        self._editedKey = State(initialValue: song.wrappedValue.key ?? "")
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
                        
                        // Основная информация о песне
                        songInfoCard
                        
                        // Музыкальные параметры
                        musicParametersCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(NSLocalizedString("Edit Song", comment: "Navigation title for edit song screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
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
                            gradient: Gradient(colors: [Color.orange, Color.red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(NSLocalizedString("Edit your song", comment: "Header text for edit song screen"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Song Info Card
    private var songInfoCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(NSLocalizedString("Song information", comment: "Section title for song information"))
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
                // Название песни
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Song title", comment: "Label for song title field"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField(NSLocalizedString("Enter song name", comment: "Placeholder text for song name input"), text: $editedTitle)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Продолжительность
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Duration", comment: "Label for song duration section"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Minutes", comment: "Label for minutes input field"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("0", value: $editedDurationMinutes, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        Text(":")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                        
                        VStack(spacing: 4) {
                            Text(NSLocalizedString("Seconds", comment: "Label for seconds input field"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("0", value: $editedDurationSeconds, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(NSLocalizedString("Done", comment: "Button to finish keyboard input")) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                           to: nil,
                                                           from: nil,
                                                           for: nil)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.top, 16)
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
    
    // MARK: - Music Parameters Card
    private var musicParametersCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(NSLocalizedString("Music parameters", comment: "Section title for music parameters"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Параметры
            VStack(spacing: 16) {
                // BPM
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(NSLocalizedString("BPM (Beats per minute)", comment: "Label for BPM input field"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(editedBpm)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    
                    TextField(NSLocalizedString("120", comment: "Placeholder for BPM input field"), value: $editedBpm, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Key
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Musical key", comment: "Label for musical key input field"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField(NSLocalizedString("C, Am, F#, etc.", comment: "Placeholder for musical key input field"), text: $editedKey)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
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
    
    // MARK: - Buttons
    private var cancelButton: some View {
        Button(NSLocalizedString("Cancel", comment: "Cancel button in edit song screen")) {
            dismiss()
        }
        .font(.body)
        .foregroundColor(.secondary)
    }
    
    private var saveButton: some View {
        Button(NSLocalizedString("Save", comment: "Save button in edit song screen")) {
            saveSong()
        }
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.blue]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
        .disabled(editedTitle.isEmpty || (editedDurationMinutes == 0 && editedDurationSeconds == 0))
        .opacity((editedTitle.isEmpty || (editedDurationMinutes == 0 && editedDurationSeconds == 0)) ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Methods
    private func saveSong() {
        // Validate data
        if editedTitle.isEmpty || (editedDurationMinutes == 0 && editedDurationSeconds == 0) {
            return
        }
        
        // Log operation for debugging
        logger.info("Saving song with key: \(editedKey.isEmpty ? "nil" : editedKey, privacy: .public)")
        
        // Update the song with edited values
        var updatedSong = song
        updatedSong.title = editedTitle
        updatedSong.durationMinutes = editedDurationMinutes
        updatedSong.durationSeconds = editedDurationSeconds
        updatedSong.bpm = editedBpm
        updatedSong.key = editedKey.isEmpty ? nil : editedKey
        
        // Update the binding
        song = updatedSong
        
        // Close modal
        dismiss()
    }
}

// MARK: - String Extension
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
