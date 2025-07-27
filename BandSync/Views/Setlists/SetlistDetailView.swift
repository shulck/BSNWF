//
//  SetlistDetailView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct SetlistDetailView: View {
    @StateObject private var viewModel: SetlistDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    // НОВОЕ: State для подтверждения отмены
    @State private var showingCancelConfirmation = false
    
    init(setlist: Setlist) {
        _viewModel = StateObject(wrappedValue: SetlistDetailViewModel(setlist: setlist))
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    var body: some View {
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
            
            // Основной контент в одном List
            List {
                // Header Section
                Section {
                    headerContent
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                
                // Songs Section
                Section {
                    if viewModel.setlist.songs.isEmpty {
                        emptyStateView
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.setlist.songs.indices, id: \.self) { index in
                            SongRowView(
                                song: viewModel.setlist.songs[index],
                                index: index,
                                isEditing: viewModel.isEditing,
                                timeFormatter: timeFormatter,
                                onEdit: {
                                    viewModel.editingSongIndex = index
                                    viewModel.showEditSong = true
                                },
                                onDelete: {
                                    viewModel.deleteSong(at: IndexSet([index]))
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: viewModel.isEditing ? viewModel.moveSong : nil)
                        .onDelete(perform: viewModel.isEditing ? viewModel.deleteSong : nil)
                        
                        // Timing view button
                        if viewModel.setlist.concertDate != nil && !viewModel.setlist.songs.isEmpty {
                            timingButton
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                
                // Пустая секция для отступа от нижней панели
                Section {
                    Color.clear
                        .frame(height: 40)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                
                // Сообщение об ошибке
                if let error = viewModel.errorMessage {
                    Section {
                        errorView(error)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                // Добавляем больше пространства для табулятора
                Color.clear.frame(height: 60)
            }
            .refreshable {
                // Pull to refresh если нужно
            }
            
            // Loading overlay
            if viewModel.isLoading {
                loadingView
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit" : "Setlist")
        .navigationBarTitleDisplayMode(.inline)
        // НОВОЕ: Скрываем стандартную кнопку Back в режиме редактирования
        .navigationBarBackButtonHidden(viewModel.isEditing)
        .toolbar {
            improvedToolbarContent
        }
        // Подтверждение удаления
        .alert("Delete setlist?".localized, isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Delete".localized, role: .destructive) {
                viewModel.deleteSetlist {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this setlist? This action cannot be undone.".localized)
        }
        // НОВОЕ: Подтверждение отмены изменений
        .alert("Discard Changes".localized, isPresented: $showingCancelConfirmation) {
            Button("Keep Editing".localized, role: .cancel) {}
            Button("Discard".localized, role: .destructive) {
                viewModel.cancelEditing()
            }
        } message: {
            Text("Your changes will be lost if you go back without saving.".localized)
        }
        .sheet(isPresented: $viewModel.showAddSong) {
            AddSongView(setlist: $viewModel.setlist, onSave: {
                viewModel.updateSetlist()
            })
        }
        .sheet(isPresented: $viewModel.showImportSongs) {
            ImportSongsView(selectedSongs: $viewModel.setlist.songs, useTimings: viewModel.setlist.concertDate != nil) {
                viewModel.updateSetlist()
            }
        }
        .sheet(isPresented: $viewModel.showExportView) {
            SetlistExportView(setlist: viewModel.setlist)
        }
        .sheet(isPresented: $viewModel.showTimingView) {
            TimingDetailView(setlist: viewModel.setlist)
        }
        .sheet(isPresented: $viewModel.showEditSong, onDismiss: {
            viewModel.updateSetlist()
            viewModel.editingSongIndex = nil
        }) {
            if let index = viewModel.editingSongIndex, index < viewModel.setlist.songs.count {
                EditSongView(song: Binding(
                    get: { viewModel.setlist.songs[index] },
                    set: { newValue in
                        var updatedSongs = viewModel.setlist.songs
                        updatedSongs[index] = newValue
                        viewModel.setlist.songs = updatedSongs
                    }
                ))
            }
        }
    }
    
    // MARK: - Header Content
    private var headerContent: some View {
        VStack(spacing: 16) {
            // Компактный header
            HStack(spacing: 12) {
                // Маленькая иконка
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Название сетлиста
                    if viewModel.isEditing {
                        TextField("Setlist Name", text: $viewModel.editName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        Text(viewModel.setlist.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    // Компактная статистика
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(viewModel.setlist.songs.count) " + String.ukrainianSongsPlural(count: viewModel.setlist.songs.count))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(viewModel.setlist.formattedTotalDuration)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        if viewModel.setlist.concertDate != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Timed".localized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "music.note.plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Songs Yet".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add some songs to get started".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if AppState.shared.hasEditPermission(for: .setlists) {
                VStack(spacing: 12) {
                    Button("Add First Song") {
                        viewModel.showAddSong = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Button("Import from Other Setlists") {
                        viewModel.showImportSongs = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Timing Button
    private var timingButton: some View {
        Button {
            viewModel.showTimingView = true
        } label: {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("View Timing".localized)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Saving changes...".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - НОВЫЙ УЛУЧШЕННЫЙ TOOLBAR
    @ToolbarContentBuilder
    private var improvedToolbarContent: some ToolbarContent {
        // Кастомная кнопка Back в режиме редактирования
        if viewModel.isEditing {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back".localized)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        
        // Основная кнопка действий
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isEditing {
                // В режиме редактирования - меню с Save и другими действиями
                Menu {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        Label("Save Changes", systemImage: "checkmark")
                    }
                    
                    Divider()
                    
                    Button {
                        viewModel.showAddSong = true
                    } label: {
                        Label("Add Song", systemImage: "music.note.plus")
                    }
                    
                    Button {
                        viewModel.showImportSongs = true
                    } label: {
                        Label("Import Songs".localized, systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            } else {
                // В обычном режиме - меню с действиями
                Menu {
                    if AppState.shared.hasEditPermission(for: .setlists) {
                        Button {
                            viewModel.startEditing()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Label("Delete Setlist", systemImage: "trash")
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        viewModel.showExportView = true
                    } label: {
                        Label("Export to PDF", systemImage: "arrow.up.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: Song
    let index: Int
    let isEditing: Bool
    let timeFormatter: DateFormatter
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: isEditing ? onEdit : {}) {
            HStack(spacing: 12) {
                // Номер песни
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Информация о песне
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        Text("\(song.bpm) BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let key = song.key, !key.isEmpty {
                            Text("• \(key)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let startTime = song.startTime {
                            Text("• \(timeFormatter.string(from: startTime))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Продолжительность и редактирование
                VStack(alignment: .trailing, spacing: 4) {
                    Text(song.formattedDuration)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    if isEditing {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu(menuItems: {
            if isEditing {
                Button("Edit") {
                    onEdit()
                }
                
                Button("Delete", role: .destructive) {
                    showDeleteAlert = true
                }
            }
        })
        .alert("Delete Song", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(song.title)\"?")
        }
    }
}

// MARK: - Add Song View
struct AddSongView: View {
    @Binding var setlist: Setlist
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var bpm = ""
    @State private var key = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Song Information") {
                    TextField("Song Title", text: $title)
                    
                    HStack {
                        TextField("Minutes", text: $minutes)
                            .keyboardType(.numberPad)
                        Text(":")
                        TextField("Seconds", text: $seconds)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("BPM", text: $bpm)
                        .keyboardType(.numberPad)
                    
                    TextField("Key (Optional)", text: $key)
                }
            }
            .navigationTitle("Add Song".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSong()
                    }
                    .disabled(title.isEmpty || (minutes.isEmpty && seconds.isEmpty) || bpm.isEmpty)
                }
            }
        }
    }
    
    private func addSong() {
        guard !title.isEmpty else { return }
        
        let min = Int(minutes) ?? 0
        let sec = Int(seconds) ?? 0
        let bpmValue = Int(bpm) ?? 120
        
        if min == 0 && sec == 0 { return }
        
        let newSong = Song(
            title: title,
            durationMinutes: min,
            durationSeconds: sec,
            bpm: bpmValue,
            key: key.isEmpty ? nil : key
        )
        
        var updatedSetlist = setlist
        updatedSetlist.songs.append(newSong)
        setlist = updatedSetlist
        
        onSave()
        dismiss()
    }
}

// MARK: - ViewModel
class SetlistDetailViewModel: ObservableObject {
    @Published var setlist: Setlist
    @Published var isEditing = false
    @Published var showAddSong = false
    @Published var showImportSongs = false
    @Published var showDeleteConfirmation = false
    @Published var showExportView = false
    @Published var showTimingView = false
    @Published var editingSongIndex: Int? = nil
    @Published var showEditSong = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var editName = ""
    
    init(setlist: Setlist) {
        self.setlist = setlist
    }
    
    func startEditing() {
        editName = setlist.name
        isEditing = true
    }
    
    func cancelEditing() {
        editName = ""
        isEditing = false
    }
    
    func saveChanges() {
        if !editName.isEmpty && editName != setlist.name {
            setlist.name = editName
        }
        updateSetlist()
        isEditing = false
    }
    
    func deleteSong(at offsets: IndexSet) {
        var updatedSongs = setlist.songs
        updatedSongs.remove(atOffsets: offsets)
        setlist.songs = updatedSongs
    }
    
    func moveSong(from source: IndexSet, to destination: Int) {
        var updatedSongs = setlist.songs
        updatedSongs.move(fromOffsets: source, toOffset: destination)
        setlist.songs = updatedSongs
    }
    
    func updateSetlist() {
        isLoading = true
        errorMessage = nil
        
        SetlistService.shared.updateSetlist(setlist) { [weak self] success in
            DispatchQueue.main.async {
                self?.isLoading = false
                if !success {
                    self?.errorMessage = "Failed to save changes"
                }
            }
        }
    }
    
    func deleteSetlist(completion: @escaping () -> Void) {
        SetlistService.shared.deleteSetlist(setlist)
        completion()
    }
}
