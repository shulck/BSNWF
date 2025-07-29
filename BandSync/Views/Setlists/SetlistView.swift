//
//  SetlistView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI
import os.log

struct SetlistViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    private let logger = Logger(subsystem: "com.bandsync.app", category: "SetlistView")
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            SetlistView()
        }
        .onAppear {
            // ИСПРАВЛЕНИЕ: Отложенная инициализация сервисов
            DispatchQueue.main.async {
                _ = SetlistService.shared // Ленивая инициализация
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetTab1"))) { _ in
            logger.info("Resetting setlist navigation")
            navigationPath = NavigationPath()
        }
    }
}

struct SetlistView: View {
    @StateObject private var service = SetlistService.shared
    @State private var showAdd = false
    @State private var searchText = ""

    var filteredSetlists: [Setlist] {
        if searchText.isEmpty {
            return service.setlists
        } else {
            return service.setlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if service.setlists.isEmpty && !service.isLoading {
                // Empty state
                emptyStateView
            } else {
                // Поисковая строка
                searchBarView
                
                // Список сетлистов
                setlistsGridView
            }
        }
        .navigationTitle("Setlists".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            if let groupId = AppState.shared.user?.groupId {
                service.fetchSetlists(for: groupId)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSetlistView()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Your stage awaits".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create first setlist".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: { showAdd = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Setlist".localized)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
                .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search setlists...".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Setlists List
    private var setlistsGridView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSetlists) { setlist in
                    NavigationLink(destination: SetlistDetailView(setlist: setlist)) {
                        SetlistCardView(setlist: setlist) {
                            deleteSetlist(setlist)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            if let groupId = AppState.shared.user?.groupId {
                service.fetchSetlists(for: groupId)
            }
        }
        .overlay(
            Group {
                if service.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(12)
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    private func deleteSetlist(_ setlist: Setlist) {
        service.deleteSetlist(setlist)
    }
}

// MARK: - Setlist Card Component
struct SetlistCardView: View {
    let setlist: Setlist
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Левая часть - иконка
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Основная информация
            VStack(alignment: .leading, spacing: 8) {
                Text(setlist.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(setlist.formattedTotalDuration, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("\(setlist.songs.count) " + String.ukrainianSongsPlural(count: setlist.songs.count), systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                // Превью песен
                if !setlist.songs.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(setlist.songs.prefix(2)), id: \.id) { song in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                
                                Text(song.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if setlist.songs.count > 2 {
                            Text(String(format: "Plus more".localized, setlist.songs.count - 2))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 10)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Кнопка меню
            Button(action: { showDeleteAlert = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .padding(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .alert("Delete Setlist".localized, isPresented: $showDeleteAlert) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this setlist? This action cannot be undone.".localized)
        }
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let icon: String
    let value: String
    var label: String = ""
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
