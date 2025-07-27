import SwiftUI
import MapKit

struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var setlistService = SetlistService.shared
    @State private var showingSetlistSelector = false
    @State private var showingLocationPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLocation: LocationDetails?
    @State private var showingScheduleEditor = false
    @State private var showingNavigationOptions = false
    @State private var navigationCoordinate: CLLocationCoordinate2D?
    @State private var navigationName: String = ""
    @State private var currentViewController: UIViewController?
    
    @State private var isRecurring = false
    @State private var endDate = Date()
    
    @State private var additionalContacts: [TempContact] = []
    @State private var showingContactEditor = false
    @State private var editingContactIndex: Int? = nil
    
    @State private var event: Event
    
    init(initialDate: Date = Date()) {
        _event = State(initialValue: Event(
            title: "",
            date: initialDate,
            type: .concert,
            status: .booked,
            location: nil,
            organizerName: nil,
            organizerEmail: nil,
            organizerPhone: nil,
            coordinatorName: nil,
            coordinatorEmail: nil,
            coordinatorPhone: nil,
            hotelName: nil,
            hotelAddress: nil,
            hotelCheckIn: nil,
            hotelCheckOut: nil,
            hotelBreakfastIncluded: nil,
            fee: nil,
            currency: "EUR",
            notes: nil,
            schedule: [],
            setlistId: nil,
            groupId: AppState.shared.user?.groupId ?? "",
            isPersonal: false
        ))
        
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: initialDate) ?? initialDate
        _endDate = State(initialValue: nextDay)
    }

    var body: some View {
        NavigationView {
            Form {
                BasicInfoSection
                PrivacySection
                RecurringEventsSection
                LocationSection
                FeeSection
                OrganizerSection
                CoordinatorSection
                AdditionalContactsSection
                AccommodationSection
                NotesSection
                ScheduleSection
                ErrorSection
            }
            .navigationTitle("New event".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveEvent()
                    }
                    .disabled(event.title.isEmpty || isLoading)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized, role: .cancel) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSetlistSelector) {
                SetlistSelectorView(selectedSetlistId: $event.setlistId)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
                    .onDisappear {
                        if let location = selectedLocation {
                            event.location = location.name + ", " + location.address
                        }
                    }
            }
            .sheet(isPresented: $showingScheduleEditor) {
                ScheduleEditorSheet(schedule: $event.schedule)
            }
            .sheet(isPresented: $showingContactEditor) {
                ContactEditorSheet(
                    contact: editingContactIndex != nil ? additionalContacts[editingContactIndex!] : TempContact(),
                    onSave: { updatedContact in
                        if let index = editingContactIndex {
                            additionalContacts[index] = updatedContact
                        } else {
                            additionalContacts.append(updatedContact)
                        }
                        editingContactIndex = nil
                    }
                )
            }
            .overlay(Group {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                }
            })
            .onAppear {
                if let groupId = AppState.shared.user?.groupId {
                    setlistService.fetchSetlists(for: groupId)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var BasicInfoSection: some View {
        Section(header: Text("basic".localized)) {
            TextField("Title".localized, text: $event.title)
            
            DatePicker("Date".localized, selection: $event.date)
            
            Toggle("Recurring Event".localized, isOn: $isRecurring)
            
            if isRecurring {
                DatePicker("End Date".localized, selection: $endDate, in: event.date..., displayedComponents: .date)
                    .onChange(of: event.date) { oldValue, newValue in
                        if endDate < newValue {
                            endDate = newValue
                        }
                    }
            }
            
            Picker("Type".localized, selection: $event.type) {
                ForEach(EventType.allCases, id: \.self) {
                    Text($0.rawValue.localized).tag($0)
                }
            }
            
            Picker("Status".localized, selection: $event.status) {
                ForEach(EventStatus.allCases, id: \.self) {
                    Text($0.rawValue.localized).tag($0)
                }
            }
            
            if [.concert, .festival, .rehearsal].contains(event.type) {
                Button {
                    showingSetlistSelector = true
                } label: {
                    HStack {
                        Text("setlist".localized)
                        Spacer()
                        Text(getSetlistName())
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
    }
    
    private var PrivacySection: some View {
        Section(header: Text("privacy".localized)) {
            Toggle("Personal Event".localized, isOn: $event.isPersonal)
                .onChange(of: event.isPersonal) { oldValue, newValue in
                    if newValue {
                        event.createdBy = AppState.shared.user?.id
                    }
                }
            
            if event.isPersonal {
                Text("Event visible only to you".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var RecurringEventsSection: some View {
        Group {
            if isRecurring {
                Section(header: Text("Recurring Events".localized)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "Will create events".localized, calculateNumberOfEvents()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(event.date) + " " + "to".localized + " " + formatDate(endDate))
                            .font(.headline)
                        
                        if calculateNumberOfEvents() > 7 {
                            Text("Warning many events".localized)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var LocationSection: some View {
        Section(header: Text("location".localized)) {
            Button(action: {
                showingLocationPicker = true
            }) {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                    Text("Select on map".localized)
                }
            }
            
            if let location = selectedLocation {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                    Text(location.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
                
                Button("Clear location".localized) {
                    selectedLocation = nil
                    event.location = nil
                }
                .foregroundColor(.red)
            } else {
                TextField("Venue".localized, text: Binding(
                    get: { event.location ?? "" },
                    set: { event.location = $0.isEmpty ? nil : $0 }
                ))
            }
        }
    }
    
    private var FeeSection: some View {
        Group {
            if [.concert, .festival].contains(event.type) {
                Section(header: Text("Fee".localized)) {
                    HStack {
                        TextField("Amount".localized, value: Binding(
                            get: { event.fee ?? 0 },
                            set: { event.fee = $0 > 0 ? $0 : nil }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        
                        TextField("Currency".localized, text: Binding(
                            get: { event.currency ?? "EUR" },
                            set: { event.currency = $0.isEmpty ? "EUR" : $0 }
                        ))
                        .frame(width: 80)
                    }
                }
            }
        }
    }
    
    private var OrganizerSection: some View {
        Group {
            if [.concert, .festival].contains(event.type) {
                Section(header: Text("organizer".localized)) {
                    TextField("Name".localized, text: Binding(
                        get: { event.organizerName ?? "" },
                        set: { event.organizerName = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Email".localized, text: Binding(
                        get: { event.organizerEmail ?? "" },
                        set: { event.organizerEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    TextField("Phone".localized, text: Binding(
                        get: { event.organizerPhone ?? "" },
                        set: { event.organizerPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }
            }
        }
    }
    
    private var CoordinatorSection: some View {
        Group {
            if [.concert, .festival].contains(event.type) {
                Section(header: Text("coordinator".localized)) {
                    TextField("Name".localized, text: Binding(
                        get: { event.coordinatorName ?? "" },
                        set: { event.coordinatorName = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("Email".localized, text: Binding(
                        get: { event.coordinatorEmail ?? "" },
                        set: { event.coordinatorEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    TextField("Phone".localized, text: Binding(
                        get: { event.coordinatorPhone ?? "" },
                        set: { event.coordinatorPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }
            }
        }
    }
    
    private var AdditionalContactsSection: some View {
        Group {
            if [.concert, .festival].contains(event.type) {
                Section(header: HStack {
                    Text("Additional Contacts".localized)
                    Spacer()
                    Button(action: {
                        editingContactIndex = nil
                        showingContactEditor = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }) {
                    if additionalContacts.isEmpty {
                        Text("No additional contacts added".localized)
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(additionalContacts.indices, id: \.self) { index in
                            let contact = additionalContacts[index]
                            Button(action: {
                                editingContactIndex = index
                                showingContactEditor = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.role)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if !contact.email.isEmpty {
                                        Text(contact.email)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    if !contact.phone.isEmpty {
                                        Text(contact.phone)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteContact)
                    }
                }
            }
        }
    }
    
    private var AccommodationSection: some View {
        Group {
            if [.concert, .festival, .photoshoot].contains(event.type) {
                Section(header: Text("accommodation".localized)) {
                    TextField("Hotel name".localized, text: Binding(
                        get: { event.hotelName ?? "" },
                        set: { event.hotelName = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.words)

                    TextField("Hotel address".localized, text: Binding(
                        get: { event.hotelAddress ?? "" },
                        set: { event.hotelAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.words)

                    if let hotelName = event.hotelName, !hotelName.isEmpty {
                        DatePicker("Check-in".localized, selection: Binding(
                            get: { event.hotelCheckIn ?? event.date },
                            set: { event.hotelCheckIn = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker("Check-out".localized, selection: Binding(
                            get: { event.hotelCheckOut ?? Calendar.current.date(byAdding: .day, value: 1, to: event.date)! },
                            set: { event.hotelCheckOut = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        HStack {
                            Image(systemName: event.hotelBreakfastIncluded == true ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(event.hotelBreakfastIncluded == true ? .green : .gray)
                                .font(.title3)
                                
                            Text("Breakfast included".localized)
                                .font(.body)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { event.hotelBreakfastIncluded ?? false },
                                set: { event.hotelBreakfastIncluded = $0 }
                            ))
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            event.hotelBreakfastIncluded = !(event.hotelBreakfastIncluded ?? false)
                        }
                        
                        if let address = event.hotelAddress, !address.isEmpty {
                            Button {
                                checkRouteToHotel(address)
                            } label: {
                                Label("Check route".localized, systemImage: "map")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var NotesSection: some View {
        Section(header: Text("notes".localized)) {
            TextEditor(text: Binding(
                get: { event.notes ?? "" },
                set: { event.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 100)
        }
    }
    
    private var ScheduleSection: some View {
        Section(header: Text("Daily Schedule".localized)) {
            Button {
                showingScheduleEditor = true
            } label: {
                HStack {
                    Text("schedule".localized)
                    Spacer()
                    if let schedule = event.schedule, !schedule.isEmpty {
                        Text("\(schedule.count) " + "items".localized)
                            .foregroundColor(.gray)
                    } else {
                        Text("Add schedule".localized)
                            .foregroundColor(.blue)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            
            if let schedule = event.schedule, !schedule.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(schedule.prefix(3), id: \.self) { item in
                        Text("• \(item)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if schedule.count > 3 {
                        Text(String(format: "And more".localized, schedule.count - 3))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
    
    private var ErrorSection: some View {
        Group {
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteContact(at offsets: IndexSet) {
        additionalContacts.remove(atOffsets: offsets)
    }
    
    private func calculateNumberOfEvents() -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: event.date)
        let endDateDay = calendar.startOfDay(for: endDate)
        
        guard let days = calendar.dateComponents([.day], from: startDate, to: endDateDay).day else {
            return 1
        }
        
        return max(1, days + 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getSetlistName() -> String {
        if let setlistId = event.setlistId,
           let setlist = setlistService.setlists.first(where: { $0.id == setlistId }) {
            return setlist.name
        }
        return "Not selected".localized
    }
    
    private func checkRouteToHotel(_ address: String) {
        NavigationService.shared.navigateToAddress(address, name: event.hotelName ?? "Hotel".localized)
    }
    
    private func saveEvent() {
        guard let groupId = AppState.shared.user?.groupId else {
            errorMessage = "Could not determine group".localized
            return
        }
        
        isLoading = true
        event.groupId = groupId
        
        if isRecurring {
            saveRecurringEvents()
        } else {
            saveSingleEvent(event)
        }
    }
    
    private func saveRecurringEvents() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: event.date)
        let endDateDay = calendar.startOfDay(for: endDate)
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: event.date)
        
        let group = DispatchGroup()
        var anyFailed = false
        
        var currentDate = startDate
        var eventsToCreate: [Event] = []
        
        while currentDate <= endDateDay {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            if let fullDate = calendar.date(from: dateComponents) {
                var newEvent = event
                newEvent.id = UUID().uuidString
                newEvent.date = fullDate
                
                if let checkIn = event.hotelCheckIn {
                    let dayDifference = calendar.dateComponents([.day], from: event.date, to: fullDate).day ?? 0
                    newEvent.hotelCheckIn = calendar.date(byAdding: .day, value: dayDifference, to: checkIn)
                }
                
                if let checkOut = event.hotelCheckOut {
                    let dayDifference = calendar.dateComponents([.day], from: event.date, to: fullDate).day ?? 0
                    newEvent.hotelCheckOut = calendar.date(byAdding: .day, value: dayDifference, to: checkOut)
                }
                
                newEvent.hotelBreakfastIncluded = event.hotelBreakfastIncluded
                
                eventsToCreate.append(newEvent)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDateDay
        }
        
        for eventToCreate in eventsToCreate {
            group.enter()
            
            EventService.shared.addEvent(eventToCreate) { success, eventId in
                if success {
                    if let eventId = eventId {
                        NotificationManager.shared.scheduleEventNotification(
                            title: eventToCreate.title,
                            date: eventToCreate.date,
                            eventId: eventId
                        )
                    }
                    
                    if eventToCreate.date == event.date {
                        var eventWithId = eventToCreate
                        eventWithId.id = eventId
                        saveContacts(for: eventWithId)
                    }
                } else {
                    anyFailed = true
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            
            if anyFailed {
                errorMessage = "Some events failed to save".localized
            } else {
                dismiss()
            }
        }
    }
    
    private func saveSingleEvent(_ eventToSave: Event) {
        var updatedEvent = eventToSave
        updatedEvent.createdBy = AppState.shared.user?.id
        
        if updatedEvent.type == .personal {
            updatedEvent.isPersonal = true
        }
        
        EventService.shared.addEvent(updatedEvent) { success, eventId in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    if let eventId = eventId {
                        NotificationManager.shared.scheduleEventNotification(
                            title: updatedEvent.title,
                            date: updatedEvent.date,
                            eventId: eventId
                        )
                    }
                    
                    var eventWithId = updatedEvent
                    eventWithId.id = eventId
                    saveContacts(for: eventWithId)
                    
                    dismiss()
                } else {
                    errorMessage = "Failed to save event".localized
                }
            }
        }
    }

    private func isContactValid(name: String?, email: String?, phone: String?) -> Bool {
        let filledFields = [
            !(name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
            !(email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
            !(phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        ].filter { $0 }.count
        
        return filledFields >= 2
    }

    private func saveContacts(for event: Event) {
        guard event.id != nil else {
            print("[AddEventView] Cannot save contacts: event ID is missing")
            return
        }
        
        if isContactValid(name: event.organizerName, email: event.organizerEmail, phone: event.organizerPhone) {
            let organizerContact = Contact(
                name: event.organizerName ?? "",
                email: event.organizerEmail ?? "",
                phone: event.organizerPhone ?? "",
                role: "Organizers".localized,
                groupId: event.groupId,
                eventTag: event.title,
                eventType: event.type.rawValue
            )
            ContactService.shared.addContact(organizerContact) { success in
                if !success {
                    print("[AddEventView] Failed to save organizer contact")
                }
            }
        }
        
        if isContactValid(name: event.coordinatorName, email: event.coordinatorEmail, phone: event.coordinatorPhone) {
            let coordinatorContact = Contact(
                name: event.coordinatorName ?? "",
                email: event.coordinatorEmail ?? "",
                phone: event.coordinatorPhone ?? "",
                role: "Coordinators".localized,
                groupId: event.groupId,
                eventTag: event.title,
                eventType: event.type.rawValue
            )
            ContactService.shared.addContact(coordinatorContact) { success in
                if !success {
                    print("[AddEventView] Failed to save coordinator contact")
                }
            }
        }
        
        for tempContact in additionalContacts {
            if tempContact.isValid {
                let contact = Contact(
                    name: tempContact.name,
                    email: tempContact.email,
                    phone: tempContact.phone,
                    role: tempContact.role,
                    groupId: event.groupId,
                    eventTag: event.title,
                    eventType: event.type.rawValue
                )
                ContactService.shared.addContact(contact) { success in
                    if !success {
                        print("[AddEventView] Failed to save additional contact: \(tempContact.name)")
                    }
                }
            }
        }
    }
}
