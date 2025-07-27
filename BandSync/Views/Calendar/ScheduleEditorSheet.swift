//
//  ScheduleEditorSheet.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 02.04.2025.
//
import SwiftUI

struct ScheduleItem: Identifiable, Equatable {
    var id = UUID()
    var time: String
    var description: String
    
    var formatted: String {
        "\(time) - \(description)"
    }
    
    static func fromString(_ string: String) -> ScheduleItem {
        let components = string.split(separator: " - ", maxSplits: 1)
        if components.count == 2 {
            return ScheduleItem(time: String(components[0]), description: String(components[1]))
        } else {
            return ScheduleItem(time: "", description: string)
        }
    }
}

struct ScheduleEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var schedule: [String]?
    
    @State private var items: [ScheduleItem] = []
    @State private var editingItem: ScheduleItem?
    @State private var showingItemEditor = false
    
    // Time picker options
    private let hourOptions = Array(0...23)
    private let minuteOptions = ["00", "05", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55"]
    
    var body: some View {
        NavigationView {
            VStack {
                scheduleList
                
                Button(action: {
                    // Create a new item with default values
                    editingItem = ScheduleItem(time: "09:00", description: "")
                    showingItemEditor = true
                }) {
                    Label("Add Schedule Item".localized, systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Daily Schedule".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        // Sort items by time before saving
                        let sortedItems = items.sorted { 
                            let hour1 = getHour(from: $0.time)
                            let hour2 = getHour(from: $1.time)
                            if hour1 == hour2 {
                                return getMinute(from: $0.time) < getMinute(from: $1.time)
                            }
                            return hour1 < hour2
                        }
                        
                        // Save formatted schedule strings
                        schedule = sortedItems.isEmpty ? nil : sortedItems.map { $0.formatted }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingItemEditor) {
                if let item = editingItem {
                    scheduleItemEditor(item: item)
                }
            }
            .onAppear {
                if let existingSchedule = schedule {
                    items = existingSchedule.map { ScheduleItem.fromString($0) }
                }
            }
        }
    }
    
    private var scheduleList: some View {
        List {
            if items.isEmpty {
                Text("No schedule items".localized)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
                    scheduleItemRow(item: item)
                }
                .onMove { source, destination in
                    items.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }
            }
        }
    }
    
    private func scheduleItemRow(item: ScheduleItem) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.time)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 70, alignment: .leading)
                    
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button {
                // Create a deep copy of the existing item for editing
                editingItem = ScheduleItem(id: item.id, time: item.time, description: item.description)
                showingItemEditor = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button {
                if let index = items.firstIndex(where: { $0.id == item.id }) {
                    items.remove(at: index)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Create a deep copy of the existing item for editing
            editingItem = ScheduleItem(id: item.id, time: item.time, description: item.description)
            showingItemEditor = true
        }
    }
    
    @ViewBuilder
    private func scheduleItemEditor(item: ScheduleItem) -> some View {
        NavigationView {
            Form {
                Section(header: Text("time".localized)) {
                    HStack {
                        Picker("Hour".localized, selection: Binding(
                            get: { self.getHour(from: item.time) },
                            set: { hour in
                                let minute = self.getMinute(from: item.time)
                                let newTime = String(format: "%02d:%02d", hour, minute)
                                
                                if self.editingItem?.id == item.id {
                                    self.editingItem?.time = newTime
                                }
                            }
                        )) {
                            ForEach(hourOptions, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                        
                        Text(":")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("Minute".localized, selection: Binding(
                            get: { self.getMinuteString(from: item.time) },
                            set: { newMinute in
                                let hour = self.getHour(from: item.time)
                                let newTime = String(format: "%02d:%@", hour, newMinute)
                                
                                if self.editingItem?.id == item.id {
                                    self.editingItem?.time = newTime
                                }
                            }
                        )) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text(minute).tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                    }
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("description".localized)) {
                    TextEditor(text: Binding(
                        get: { self.editingItem?.description ?? "" },
                        set: { newValue in
                            if self.editingItem?.id == item.id {
                                self.editingItem?.description = newValue
                            }
                        }
                    ))
                    .frame(minHeight: 100)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Schedule Item".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        showingItemEditor = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done".localized) {
                        if let updatedItem = editingItem {
                            // Find and update the item in the main array
                            if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
                                // Update existing item
                                items[index] = updatedItem
                            } else {
                                // Add new item
                                items.append(updatedItem)
                            }
                        }
                        
                        showingItemEditor = false
                    }
                }
            }
        }
    }
    
    // Helper functions to convert between string time and components
    private func getHour(from timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        if components.count >= 1, let hour = Int(components[0]) {
            return hour
        }
        return 9 // Default hour
    }
    
    private func getMinute(from timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        if components.count >= 2, let minute = Int(components[1]) {
            return minute
        }
        return 0 // Default minute
    }
    
    private func getMinuteString(from timeString: String) -> String {
        let components = timeString.split(separator: ":")
        if components.count >= 2 {
            let minuteStr = String(components[1])
            if minuteOptions.contains(minuteStr) {
                return minuteStr
            }
        }
        return "00" // Default minute
    }
}

struct ScheduleEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleEditorSheet(
            schedule: .constant(["09:00 - Morning rehearsal", "13:00 - Lunch break", "14:30 - Song writing"])
        )
    }
}
