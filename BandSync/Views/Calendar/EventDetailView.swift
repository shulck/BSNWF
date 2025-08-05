import SwiftUI
import MapKit
import FirebaseAuth

struct EventDetailView: View {
    @StateObject private var setlistService = SetlistService.shared
    
    // State variables
    @State private var event: Event
    @State private var originalEvent: Event
    @State private var isEditing = false
    @State private var showingSetlistSelector = false
    @State private var showingLocationPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLocation: LocationDetails?
    @State private var showingScheduleEditor = false
    @State private var showingNavigationOptions = false
    @State private var navigationCoordinate: CLLocationCoordinate2D?
    @State private var navigationName: String = ""
    @State private var currentViewController: UIViewController?
    
    // Additional contacts management
    @State private var additionalContacts: [TempContact] = []
    @State private var showingContactEditor = false
    @State private var editingContactIndex: Int?
    
    // Permission checks
    @State private var userCanEdit: Bool
    @State private var userCanDelete: Bool
    
    @Environment(\.dismiss) var dismiss
    
    init(event: Event) {
        self._event = State(initialValue: event)
        self._originalEvent = State(initialValue: event)
        self._userCanEdit = State(initialValue: Self.canEditEvent(event))
        self._userCanDelete = State(initialValue: Self.canDeleteEvent(event))
    }
    
    // Методы для получения дополнительных контактов по ролям
    private func additionalOrganizers() -> [TempContact] {
        return additionalContacts.filter { $0.role.lowercased().contains("organizer") }
    }
    
    private func additionalCoordinators() -> [TempContact] {
        return additionalContacts.filter { $0.role.lowercased().contains("coordinator") }
    }
    
    private func otherAdditionalContacts() -> [TempContact] {
        return additionalContacts.filter { contact in
            let role = contact.role.lowercased()
            return !role.contains("organizer") && !role.contains("coordinator")
        }
    }
    
    var body: some View {
        if isEditing {
            editingView
        } else {
            displayView
        }
    }
    
    // MARK: - Display View (когда не редактируем)
    
    private var displayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Event header
                eventHeaderSection

                Divider()

                // Ticket section
                if [.concert, .festival].contains(event.type) {
                    ticketDisplaySection
                    Divider()
                }

                // Location section
                locationSection
                
                Divider()
                
                // Schedule section
                if event.schedule != nil && !event.schedule!.isEmpty {
                    scheduleSection
                    Divider()
                }
                
                // Setlist section
                if [.concert, .festival, .rehearsal].contains(event.type) &&
                   event.setlistId != nil {
                    setlistSection
                    Divider()
                }
                
                // Organizer section
                if [.concert, .festival, .interview, .photoshoot].contains(event.type) &&
                   hasOrganizerData() &&
                   AppState.shared.canSeeFullEventDetails() {
                    organizerSection
                    Divider()
                }
                
                // Coordinator section
                if [.concert, .festival].contains(event.type) &&
                   hasCoordinatorData() &&
                   AppState.shared.canSeeFullEventDetails() {
                    coordinatorSection
                    Divider()
                }
                
                // Hotel section
                if [.concert, .festival, .photoshoot].contains(event.type) &&
                   hasHotelData() &&
                   AppState.shared.canSeeFullEventDetails() {
                    hotelSection
                    Divider()
                }
                
                // Fee section
                if [.concert, .festival, .interview, .photoshoot].contains(event.type) &&
                   (event.fee != nil && event.currency != nil) &&
                   AppState.shared.canSeeFullEventDetails() {
                    financesSection
                    Divider()
                }
                
                // Notes section
                if event.notes != nil && !event.notes!.isEmpty {
                    notesSection
                    Divider()
                }
                
                // Other contacts section
                if !otherAdditionalContacts().isEmpty &&
                   AppState.shared.canSeeFullEventDetails() {
                    otherContactsSection
                    Divider()
                }
                
                // Error display
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Delete button
                if userCanDelete {
                    VStack {
                        deleteButton
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .navigationTitle(NSLocalizedString("Event", comment: "Event navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if userCanEdit {
                    Button(NSLocalizedString("Edit", comment: "Edit button")) {
                        isEditing = true
                    }
                }
            }
        }
        .onAppear {
            setupOnAppear()
        }
    }
    
    // MARK: - Editing View (форма как в AddEventView)
    
    private var editingView: some View {
        Form {
            Section(header: Text(NSLocalizedString("Basic Information", comment: "Basic information section title"))) {
                TextField(NSLocalizedString("Title", comment: "Title placeholder"), text: $event.title)
                
                DatePicker(NSLocalizedString("Date", comment: "Date picker label"), selection: $event.date)
                
                Picker(NSLocalizedString("Type", comment: "Type picker label"), selection: $event.type) {
                    ForEach(EventType.allCases, id: \.self) {
                        Text(NSLocalizedString($0.rawValue, comment: "Event type")).tag($0)
                    }
                }
                
                Picker(NSLocalizedString("Status", comment: "Status picker label"), selection: $event.status) {
                    ForEach(EventStatus.allCases, id: \.self) {
                        Text(NSLocalizedString($0.rawValue, comment: "Event status")).tag($0)
                    }
                }
                
                // Setlist field (only for concerts, festivals and rehearsals)
                if [.concert, .festival, .rehearsal].contains(event.type) {
                    Button {
                        showingSetlistSelector = true
                    } label: {
                        HStack {
                            Text(NSLocalizedString("Setlist", comment: "Setlist label"))
                            Spacer()
                            Text(getSetlistName())
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
            }
            
            // СЕКЦИЯ ДЛЯ ПЕРСОНАЛЬНЫХ СОБЫТИЙ
            Section(header: Text(NSLocalizedString("Privacy", comment: "Privacy section title"))) {
                Toggle(NSLocalizedString("Personal Event", comment: "Personal event toggle"), isOn: $event.isPersonal)
                    .onChange(of: event.isPersonal) { oldValue, newValue in
                        if newValue {
                            // Если делаем событие персональным, устанавливаем создателя
                            event.createdBy = AppState.shared.user?.id
                        }
                    }
                
                if event.isPersonal {
                    Text(NSLocalizedString("Event visible only to you", comment: "Event visibility description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text(NSLocalizedString("Location", comment: "Location section title"))) {
                // Button for selecting location on map
                Button(action: {
                    showingLocationPicker = true
                }) {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("Select on map", comment: "Select on map button"))
                    }
                }
                
                // Display selected location
                if let location = selectedLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                            .font(.headline)
                        Text(location.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    // Button to clear selected location
                    Button(NSLocalizedString("Clear location", comment: "Clear location button")) {
                        selectedLocation = nil
                        event.location = nil
                    }
                    .foregroundColor(.red)
                } else {
                    TextField(NSLocalizedString("Venue", comment: "Venue placeholder"), text: Binding(
                        get: { event.location ?? "" },
                        set: { event.location = $0.isEmpty ? nil : $0 }
                    ))
                }
            }

            // Additional fields depending on event type
            if [.concert, .festival].contains(event.type) {
                // For concerts and festivals show fee information
                Section(header: Text(NSLocalizedString("Fee", comment: "Fee section title"))) {
                    HStack {
                        TextField(NSLocalizedString("Amount", comment: "Amount placeholder"), value: Binding(
                            get: { event.fee ?? 0 },
                            set: { event.fee = $0 > 0 ? $0 : nil }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        
                        TextField(NSLocalizedString("Currency", comment: "Currency placeholder"), text: Binding(
                            get: { event.currency ?? "EUR" },
                            set: { event.currency = $0.isEmpty ? "EUR" : $0 }
                        ))
                        .frame(width: 80)
                    }
                }
                // Ticket Information
                Section(header: Text(NSLocalizedString("Ticket Information", comment: "Ticket information section title"))) {
                    Toggle(NSLocalizedString("Paid Event", comment: "Paid event toggle"), isOn: Binding(
                        get: { event.isPaidEvent ?? false },
                        set: { newValue in
                            event.isPaidEvent = newValue
                            if !newValue {
                                event.ticketPurchaseUrl = nil
                            }
                        }
                    ))
                    
                    if event.isPaidEvent ?? false {
                        TextField(NSLocalizedString("Ticket Purchase URL", comment: "Ticket purchase URL placeholder"), text: Binding(
                            get: { event.ticketPurchaseUrl ?? "" },
                            set: { event.ticketPurchaseUrl = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .textContentType(.URL)
                        
                        Text(NSLocalizedString("Buy Tickets", comment: "Buy tickets text"))
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text(NSLocalizedString("Event is free", comment: "Event is free text"))
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Organizer information
                Section(header: Text(NSLocalizedString("Organizer", comment: "Organizer section title"))) {
                    TextField(NSLocalizedString("Name", comment: "Name placeholder"), text: Binding(
                        get: { event.organizerName ?? "" },
                        set: { event.organizerName = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField(NSLocalizedString("Email", comment: "Email placeholder"), text: Binding(
                        get: { event.organizerEmail ?? "" },
                        set: { event.organizerEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    TextField(NSLocalizedString("Phone", comment: "Phone placeholder"), text: Binding(
                        get: { event.organizerPhone ?? "" },
                        set: { event.organizerPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }
                
                // Coordinator (only for festivals and concerts)
                Section(header: Text(NSLocalizedString("Coordinator", comment: "Coordinator section title"))) {
                    TextField(NSLocalizedString("Name", comment: "Name placeholder"), text: Binding(
                        get: { event.coordinatorName ?? "" },
                        set: { event.coordinatorName = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField(NSLocalizedString("Email", comment: "Email placeholder"), text: Binding(
                        get: { event.coordinatorEmail ?? "" },
                        set: { event.coordinatorEmail = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    TextField(NSLocalizedString("Phone", comment: "Phone placeholder"), text: Binding(
                        get: { event.coordinatorPhone ?? "" },
                        set: { event.coordinatorPhone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)
                }
                
                // Additional Contacts Section
                Section(header: HStack {
                    Text(NSLocalizedString("Additional Contacts", comment: "Additional contacts section title"))
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
                        Text(NSLocalizedString("No additional contacts added", comment: "No additional contacts message"))
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

            // For events requiring accommodation - ОБНОВЛЕННАЯ СЕКЦИЯ С ЗАВТРАКАМИ
            if [.concert, .festival, .photoshoot].contains(event.type) {
                Section(header: Text(NSLocalizedString("Accommodation", comment: "Accommodation section title"))) {
                    TextField(NSLocalizedString("Hotel name", comment: "Hotel name placeholder"), text: Binding(
                        get: { event.hotelName ?? "" },
                        set: { event.hotelName = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.words)

                    TextField(NSLocalizedString("Hotel address", comment: "Hotel address placeholder"), text: Binding(
                        get: { event.hotelAddress ?? "" },
                        set: { event.hotelAddress = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.words)

                    // Show remaining fields only if hotel name is filled
                    if let hotelName = event.hotelName, !hotelName.isEmpty {
                        DatePicker(NSLocalizedString("Check-in", comment: "Check-in date picker"), selection: Binding(
                            get: { event.hotelCheckIn ?? event.date },
                            set: { event.hotelCheckIn = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker(NSLocalizedString("Check-out", comment: "Check-out date picker"), selection: Binding(
                            get: { event.hotelCheckOut ?? Calendar.current.date(byAdding: .day, value: 1, to: event.date)! },
                            set: { event.hotelCheckOut = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        
                        // НОВОЕ: Переключатель для завтраков
                        HStack {
                            Image(systemName: event.hotelBreakfastIncluded == true ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(event.hotelBreakfastIncluded == true ? .green : .gray)
                                .font(.title3)
                            
                            Text(NSLocalizedString("Breakfast included", comment: "Breakfast included text"))
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
                        
                        // Add button to check route to hotel if address is filled
                        if let address = event.hotelAddress, !address.isEmpty {
                            Button {
                                checkRouteToHotel(address)
                            } label: {
                                Label(NSLocalizedString("Check route", comment: "Check route button"), systemImage: "map")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }

            Section(header: Text(NSLocalizedString("Notes", comment: "Notes section title"))) {
                TextEditor(text: Binding(
                    get: { event.notes ?? "" },
                    set: { event.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
            
            // Rating section
            Section(header: Text(NSLocalizedString("Rating", comment: "Rating section title"))) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(NSLocalizedString("Rate this event", comment: "Rate this event text"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        StarRatingView(
                            rating: Binding(
                                get: { event.rating ?? 0 },
                                set: { newRating in
                                    event.rating = newRating > 0 ? newRating : nil
                                }
                            ),
                            isEditable: true
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Comment (optional)", comment: "Comment optional text"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: Binding(
                            get: { event.ratingComment ?? "" },
                            set: { event.ratingComment = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 60)
                    }
                }
            }
            
            // Daily schedule section - should always be visible
            Section(header: Text(NSLocalizedString("Daily Schedule", comment: "Daily schedule section title"))) {
                Button {
                    showingScheduleEditor = true
                } label: {
                    HStack {
                        Text(NSLocalizedString("Schedule", comment: "Schedule text"))
                        Spacer()
                        if let schedule = event.schedule, !schedule.isEmpty {
                            Text("\(schedule.count) " + NSLocalizedString("entries", comment: "Entries count text"))
                                .foregroundColor(.gray)
                        } else {
                            Text(NSLocalizedString("Add schedule", comment: "Add schedule button"))
                                .foregroundColor(.blue)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // Show schedule preview if it exists
                if let schedule = event.schedule, !schedule.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(schedule.prefix(3), id: \.self) { item in
                            Text("• \(item)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if schedule.count > 3 {
                            Text(String(format: NSLocalizedString("And %d more", comment: "And more items format"), schedule.count - 3))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            // Display errors
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(NSLocalizedString("Edit Event", comment: "Edit event navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("Save", comment: "Save button")) {
                    saveChanges()
                }
                .disabled(event.title.isEmpty || isLoading)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                    if hasChanges() {
                        showingCancelConfirmation = true
                    } else {
                        cancelEditing()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSetlistSelector) {
            SetlistSelectorView(selectedSetlistId: $event.setlistId)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(selectedLocation: $selectedLocation)
                .onDisappear {
                    // Update event location when a place is selected on the map
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
        .alert(NSLocalizedString("Discard Changes?", comment: "Discard changes alert title"), isPresented: $showingCancelConfirmation) {
            Button(NSLocalizedString("Keep Editing", comment: "Keep editing button"), role: .cancel) {}
            Button(NSLocalizedString("Discard", comment: "Discard button"), role: .destructive) {
                cancelEditing()
            }
        } message: {
            Text(NSLocalizedString("Changes will be lost", comment: "Changes will be lost message"))
        }
    }
    
    // MARK: - Display View Components
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Адаптивное название события
            GeometryReader { geometry in
                Text(event.title)
                    .font(adaptiveTitleFont(for: geometry.size.width))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: event.type.colorHex))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: adaptiveTitleHeight())
            .padding(.bottom, 4)
            
            // Рейтинг рядом с названием (компактный)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    StarRatingView(
                        rating: .constant(event.rating ?? 0),
                        isEditable: false
                    )
                    
                    if let rating = event.rating {
                        Text("(\(rating)/5)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(NSLocalizedString("No Rating", comment: "Rating display when no rating is available"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Комментарий к рейтингу
                if let comment = event.ratingComment, !comment.isEmpty {
                    Text("\"\(comment)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }
            .padding(.bottom, 4)
            
            eventTypeAndStatusRow
            
            Label(formatDate(event.date), systemImage: "calendar")
        }
        .padding(.horizontal)
    }
    
    // MARK: - Adaptive Title Helpers
    
    private func adaptiveTitleFont(for width: CGFloat) -> Font {
        let titleLength = event.title.count
        
        // Для очень широких экранов (iPad)
        if width > 600 {
            if titleLength > 30 {
                return .title2.bold()
            } else {
                return .largeTitle.bold()
            }
        }
        // Для средних экранов (iPhone Pro Max, Plus)
        else if width > 390 {
            if titleLength > 25 {
                return .title3.bold()
            } else if titleLength > 15 {
                return .title2.bold()
            } else {
                return .title.bold()
            }
        }
        // Для стандартных экранов (iPhone Pro, обычный)
        else if width > 350 {
            if titleLength > 20 {
                return .headline.bold()
            } else if titleLength > 12 {
                return .title3.bold()
            } else {
                return .title2.bold()
            }
        }
        // Для компактных экранов (iPhone Mini, SE)
        else {
            if titleLength > 15 {
                return .subheadline.bold()
            } else if titleLength > 10 {
                return .headline.bold()
            } else {
                return .title3.bold()
            }
        }
    }
    
    private func adaptiveTitleHeight() -> CGFloat {
        let titleLength = event.title.count
        
        // Примерная высота в зависимости от длины текста
        if titleLength > 30 {
            return 100 // Для очень длинных названий (3-4 строки)
        } else if titleLength > 20 {
            return 70  // Для длинных названий (2-3 строки)
        } else if titleLength > 10 {
            return 50  // Для средних названий (1-2 строки)
        } else {
            return 35  // Для коротких названий (1 строка)
        }
    }
    
    private var eventTypeAndStatusRow: some View {
        HStack(spacing: 16) {
            Label(NSLocalizedString(event.type.rawValue, comment: "Event type"), systemImage: getIconForEventType(event.type))
                .foregroundColor(Color(hex: event.type.colorHex))
            
            Label(NSLocalizedString(event.status.rawValue, comment: "Event status"), systemImage: "checkmark.circle")
                .foregroundColor(event.status.color)
        }
    }
    private var ticketDisplaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Ticket Information", comment: "Ticket information section title"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: (event.isPaidEvent ?? false) ? "creditcard.fill" : "gift.fill")
                        .foregroundColor((event.isPaidEvent ?? false) ? .orange : .green)
                    
                    Text((event.isPaidEvent ?? false) ? NSLocalizedString("Event is paid", comment: "Event is paid text") : NSLocalizedString("Event is free", comment: "Event is free text"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor((event.isPaidEvent ?? false) ? .orange : .green)
                    
                    Spacer()
                }
                
                if (event.isPaidEvent ?? false), let ticketUrl = event.ticketPurchaseUrl, !ticketUrl.isEmpty {
                    Button {
                        if let url = URL(string: ticketUrl) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Buy Tickets", comment: "Buy tickets text"))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Location", comment: "Location section title"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                EventMapView(event: event)
                
                if let location = event.location, !location.isEmpty {
                    Button {
                        showLocationDirections(address: location, name: event.title)
                    } label: {
                        Label(NSLocalizedString("Get directions", comment: "Get directions button"), systemImage: "arrow.triangle.turn.up.right.diamond")
                            .foregroundColor(.blue)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Daily Schedule", comment: "Section title for event daily schedule"))
                .font(.headline)
                .padding(.horizontal)
            
            if let schedule = event.schedule, !schedule.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(schedule, id: \.self) { item in
                        if item.contains(" - ") {
                            HStack(alignment: .top) {
                                let components = item.split(separator: " - ", maxSplits: 1)
                                if components.count == 2 {
                                    Text(String(components[0]))
                                        .bold()
                                        .frame(width: 70, alignment: .leading)
                                    
                                    Text(String(components[1]))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        } else {
                            Text(item)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var setlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Setlist", comment: "Section title for event setlist"))
                .font(.headline)
                .padding(.horizontal)
            
            if let setlistId = event.setlistId,
               let setlist = setlistService.setlists.first(where: { $0.id == setlistId }) {
                NavigationLink(destination: SetlistDetailView(setlist: setlist)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(setlist.name, systemImage: "music.note.list")
                                Text("\(setlist.songs.count) " + String.ukrainianSongsPlural(count: setlist.songs.count) + " • \(setlist.formattedTotalDuration)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            } else {
                Text(NSLocalizedString("No Setlist Selected", comment: "Message when no setlist is selected for event"))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var organizerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Organizers", comment: "Section title for event organizers"))
                .font(.headline)
                .padding(.horizontal)
            
            if hasOrganizerData() || !additionalOrganizers().isEmpty {
                VStack(spacing: 8) {
                    // Основной организатор
                    if hasOrganizerData() {
                        VStack(alignment: .leading, spacing: 8) {
                            if let name = event.organizerName, !name.isEmpty {
                                Label(name, systemImage: "person")
                            }
                            
                            if let email = event.organizerEmail, !email.isEmpty {
                                Button {
                                    openMail(email)
                                } label: {
                                    Label(email, systemImage: "envelope")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if let phone = event.organizerPhone, !phone.isEmpty {
                                Button {
                                    call(phone)
                                } label: {
                                    Label(phone, systemImage: "phone")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Дополнительные организаторы
                    ForEach(additionalOrganizers().indices, id: \.self) { index in
                        let contact = additionalOrganizers()[index]
                        additionalContactView(contact: contact)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var coordinatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Coordinators", comment: "Section title for event coordinators"))
                .font(.headline)
                .padding(.horizontal)
            
            if hasCoordinatorData() || !additionalCoordinators().isEmpty {
                VStack(spacing: 8) {
                    // Основной координатор
                    if hasCoordinatorData() {
                        VStack(alignment: .leading, spacing: 8) {
                            if let name = event.coordinatorName, !name.isEmpty {
                                Label(name, systemImage: "person")
                            }
                            
                            if let email = event.coordinatorEmail, !email.isEmpty {
                                Button {
                                    openMail(email)
                                } label: {
                                    Label(email, systemImage: "envelope")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if let phone = event.coordinatorPhone, !phone.isEmpty {
                                Button {
                                    call(phone)
                                } label: {
                                    Label(phone, systemImage: "phone")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Дополнительные координаторы
                    ForEach(additionalCoordinators().indices, id: \.self) { index in
                        let contact = additionalCoordinators()[index]
                        additionalContactView(contact: contact)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var hotelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Accommodation", comment: "Section title for event accommodation"))
                .font(.headline)
                .padding(.horizontal)
            
            if let hotelName = event.hotelName, !hotelName.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(hotelName, systemImage: "house")
                    
                    if let hotelAddress = event.hotelAddress, !hotelAddress.isEmpty {
                        Label(hotelAddress, systemImage: "location")
                        
                        Button {
                            openMaps(for: hotelAddress)
                        } label: {
                            Label(NSLocalizedString("Open in Maps", comment: "Button to open location in Maps app"), systemImage: "map")
                                .foregroundColor(.blue)
                        }
                        
                        Button {
                            NavigationService.shared.navigateToAddress(hotelAddress, name: hotelName)
                        } label: {
                            Label(NSLocalizedString("Get directions", comment: "Button to get directions to location"), systemImage: "arrow.triangle.turn.up.right.diamond")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let checkIn = event.hotelCheckIn {
                        Label(NSLocalizedString("Check-in", comment: "Hotel check-in time label") + ": \(formatDateTime(checkIn))", systemImage: "arrow.down.to.line")
                    }
                    
                    if let checkOut = event.hotelCheckOut {
                        Label(NSLocalizedString("Check-out", comment: "Hotel check-out time label") + ": \(formatDateTime(checkOut))", systemImage: "arrow.up.to.line")
                    }
                    
                    HStack {
                        Image(systemName: event.hotelBreakfastIncluded == true ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(event.hotelBreakfastIncluded == true ? .green : .red)
                        
                        Text(event.hotelBreakfastIncluded == true ? NSLocalizedString("Breakfast included", comment: "Hotel breakfast is included") : NSLocalizedString("Breakfast not included", comment: "Hotel breakfast is not included"))
                            .foregroundColor(event.hotelBreakfastIncluded == true ? .green : .secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var financesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Finances", comment: "Section title for event finances"))
                .font(.headline)
                .padding(.horizontal)
            
            if let fee = event.fee, let currency = event.currency {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Fee", comment: "Event fee label") + ": \(Int(fee)) \(currency)")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString("Notes", comment: "Section title for event notes"))
                    .font(.headline)
                
                if let notes = event.notes, !notes.isEmpty, hasLinks(in: notes) {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            
            if let notes = event.notes, !notes.isEmpty {
                TextWithLinks(text: notes)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                Text(NSLocalizedString("No Notes", comment: "Message when no notes are available"))
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Rating Section (в режиме редактирования)
    /*
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Rating", comment: "Section title for event rating"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                // Star rating display
                HStack(spacing: 4) {
                    StarRatingView(
                        rating: .constant(event.rating ?? 0),
                        isEditable: false
                    )
                    
                    if let rating = event.rating {
                        Text("(\(rating)/5)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(NSLocalizedString("No Rating", comment: "Rating display when no rating is available in second location"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Rating comment
                if let comment = event.ratingComment, !comment.isEmpty {
                    Text(comment)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                } else if event.rating != nil {
                    Text(NSLocalizedString("No Comment", comment: "Message when no rating comment is available"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    */
    
    private var otherContactsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Other Contacts", comment: "Section title for other event contacts"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(otherAdditionalContacts().indices, id: \.self) { index in
                    let contact = otherAdditionalContacts()[index]
                    contactRowView(contact: contact, index: index)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func contactRowView(contact: TempContact, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(contact.name, systemImage: "person")
                .font(.headline)
            
            Label(contact.role, systemImage: "briefcase")
                .font(.subheadline)
                .foregroundColor(.blue)
                
            if !contact.email.isEmpty {
                Button {
                    openMail(contact.email)
                } label: {
                    Label(contact.email, systemImage: "envelope")
                        .foregroundColor(.blue)
                }
            }
            
            if !contact.phone.isEmpty {
                Button {
                    call(contact.phone)
                } label: {
                    Label(contact.phone, systemImage: "phone")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func additionalContactView(contact: TempContact) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(contact.name, systemImage: "person")
            
            if !contact.email.isEmpty {
                Button {
                    openMail(contact.email)
                } label: {
                    Label(contact.email, systemImage: "envelope")
                        .foregroundColor(.blue)
                }
            }
            
            if !contact.phone.isEmpty {
                Button {
                    call(contact.phone)
                } label: {
                    Label(contact.phone, systemImage: "phone")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Label(NSLocalizedString("Delete Event", comment: "Button to delete event"), systemImage: "trash")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .alert(NSLocalizedString("Delete Event?", comment: "Alert title for delete confirmation"), isPresented: $showingDeleteConfirmation) {
            Button(NSLocalizedString("Cancel", comment: "Cancel button in delete confirmation"), role: .cancel) {}
            Button(NSLocalizedString("Delete", comment: "Delete button in delete confirmation"), role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete this event? This action cannot be undone.", comment: "Delete confirmation message"))
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteContact(at offsets: IndexSet) {
        additionalContacts.remove(atOffsets: offsets)
    }
    
    private func getSetlistName() -> String {
        if let setlistId = event.setlistId,
           let setlist = setlistService.setlists.first(where: { $0.id == setlistId }) {
            return setlist.name
        }
        return NSLocalizedString("Not Selected", comment: "Not selected text")
    }
    
    private func checkRouteToHotel(_ address: String) {
        NavigationService.shared.navigateToAddress(address, name: event.hotelName ?? NSLocalizedString("Hotel", comment: "Hotel name fallback"))
    }
    
    private func hasChanges() -> Bool {
        let hasChanges = event.title != originalEvent.title ||
                        event.date != originalEvent.date ||
                        event.type != originalEvent.type ||
                        event.status != originalEvent.status ||
                        event.location != originalEvent.location ||
                        event.notes != originalEvent.notes ||
                        event.setlistId != originalEvent.setlistId ||
                        event.organizerName != originalEvent.organizerName ||
                        event.organizerEmail != originalEvent.organizerEmail ||
                        event.organizerPhone != originalEvent.organizerPhone ||
                        event.coordinatorName != originalEvent.coordinatorName ||
                        event.coordinatorEmail != originalEvent.coordinatorEmail ||
                        event.coordinatorPhone != originalEvent.coordinatorPhone ||
                        event.hotelName != originalEvent.hotelName ||
                        event.hotelAddress != originalEvent.hotelAddress ||
                        event.hotelCheckIn != originalEvent.hotelCheckIn ||
                        event.hotelCheckOut != originalEvent.hotelCheckOut ||
                        event.hotelBreakfastIncluded != originalEvent.hotelBreakfastIncluded ||
                        event.fee != originalEvent.fee ||
                        event.currency != originalEvent.currency ||
                        event.isPersonal != originalEvent.isPersonal ||
                        event.rating != originalEvent.rating ||
                        event.ratingComment != originalEvent.ratingComment ||
                        event.isPaidEvent != originalEvent.isPaidEvent ||
                        event.ticketPurchaseUrl != originalEvent.ticketPurchaseUrl
        
        return hasChanges
    }
    
    private func setupOnAppear() {
        if let groupId = AppState.shared.user?.groupId {
            setlistService.fetchSetlists(for: groupId)
        }
        
        if selectedLocation == nil, let locationText = event.location, !locationText.isEmpty {
            geocodeEventLocation(locationText)
        }
        
        loadAdditionalContacts()
    }
    
    private func loadAdditionalContacts() {
        if let groupId = AppState.shared.user?.groupId {
            ContactService.shared.fetchContacts(for: groupId) {
                DispatchQueue.main.async {
                    let eventContacts = ContactService.shared.contactsForEvent(self.event.title)
                    // ИСКЛЮЧАЕМ основных контактов (организаторов и координаторов)
                    self.additionalContacts = eventContacts.compactMap { contact in
                        // Пропускаем организаторов и координаторов
                        if contact.role == "Organizers" || contact.role == "Coordinators" {
                            return nil
                        }
                        return TempContact(
                            name: contact.name,
                            email: contact.email,
                            phone: contact.phone,
                            role: contact.role
                        )
                    }
                }
            }
        }
    }
    
    private func cancelEditing() {
        event = originalEvent
        selectedLocation = nil
        loadAdditionalContacts()
        isEditing = false
    }
    
    private func saveChanges() {
        print("🔄 Starting save process...")
        print("📝 Event title: \(event.title)")
        print("🆔 Event ID: \(event.id ?? "nil")")
        
        // Проверяем наличие ID
        guard let eventId = event.id, !eventId.isEmpty else {
            print("❌ Cannot save event without ID")
            errorMessage = NSLocalizedString("Cannot save event: missing event ID", comment: "Cannot save event missing ID error")
            return
        }
        if (event.isPaidEvent ?? false), let urlString = event.ticketPurchaseUrl, !urlString.isEmpty {
            if !isValidURL(urlString) {
                errorMessage = NSLocalizedString("Please enter a valid ticket purchase URL", comment: "Invalid ticket URL error")
                return
            }
        }
        
        // Проверяем Firebase Auth
        guard Auth.auth().currentUser != nil else {
            print("❌ No Firebase Auth user found!")
            errorMessage = NSLocalizedString("Authentication required to save changes", comment: "Authentication required error")
            return
        }
        
        isLoading = true
        
        // Устанавливаем createdBy если не установлен
        if event.createdBy == nil {
            event.createdBy = AppState.shared.user?.id
        }
        
        print("📝 Updating event with ID: \(eventId)")
        EventService.shared.updateEvent(event) { success in
            DispatchQueue.main.async {
                print("💾 Update result: \(success)")
                self.handleSaveResult(success)
            }
        }
    }
    
    private func handleSaveResult(_ success: Bool) {
        isLoading = false
        
        if success {
            print("✅ Save successful, updating contacts...")
            saveAdditionalContacts()
            
            if let eventId = event.id {
                NotificationManager.shared.scheduleEventNotification(
                    title: event.title,
                    date: event.date,
                    eventId: eventId
                )
            }
            
            originalEvent = event
            isEditing = false
            print("✅ Edit mode disabled")
        } else {
            print("❌ Save failed")
            errorMessage = NSLocalizedString("Failed to save changes", comment: "Failed to save changes error")
        }
    }
    
    private func deleteEvent() {
        if let eventId = event.id {
            NotificationManager.shared.cancelEventNotification(eventId: eventId)
        }
        
        EventService.shared.deleteEvent(event)
        dismiss()
    }
    
    // Helper function to check if contact has at least 2 filled fields
    private func isContactValid(name: String?, email: String?, phone: String?) -> Bool {
        let filledFields = [
            !(name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
            !(email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
            !(phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        ].filter { $0 }.count
        
        return filledFields >= 2
    }
    
    private func saveAdditionalContacts() {
        guard let groupId = AppState.shared.user?.groupId else { return }
        
        // НЕ УДАЛЯЕМ все контакты! Обновляем только нужные
        
        // Save Organizer contact if at least 2 fields are filled
        if isContactValid(name: event.organizerName, email: event.organizerEmail, phone: event.organizerPhone) {
            let organizerContact = Contact(
                name: event.organizerName ?? "",
                email: event.organizerEmail ?? "",
                phone: event.organizerPhone ?? "",
                role: "Organizers",
                groupId: groupId,
                eventTag: event.title,
                eventType: event.type.rawValue
            )
            ContactService.shared.addContact(organizerContact) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.errorMessage = NSLocalizedString("Failed to Save Organizer Contact", comment: "Error message when organizer contact save fails")
                    }
                }
            }
        }
        
        // Save Coordinator contact if at least 2 fields are filled
        if isContactValid(name: event.coordinatorName, email: event.coordinatorEmail, phone: event.coordinatorPhone) {
            let coordinatorContact = Contact(
                name: event.coordinatorName ?? "",
                email: event.coordinatorEmail ?? "",
                phone: event.coordinatorPhone ?? "",
                role: "Coordinators",
                groupId: groupId,
                eventTag: event.title,
                eventType: event.type.rawValue
            )
            ContactService.shared.addContact(coordinatorContact) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.errorMessage = NSLocalizedString("Failed to Save Coordinator Contact", comment: "Error message when coordinator contact save fails")
                    }
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
                    groupId: groupId,
                    eventTag: event.title
                )
                ContactService.shared.addContact(contact) { success in
                    if !success {
                        DispatchQueue.main.async {
                            self.errorMessage = NSLocalizedString("Failed to save contact: ", comment: "Error message when contact save fails") + tempContact.name
                        }
                    }
                }
            }
        }
    }
    
    private func geocodeEventLocation(_ locationText: String) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(locationText) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            let name: String
            if let placemarkName = placemark.name {
                name = placemarkName
            } else if let eventLocation = self.event.location {
                name = eventLocation
            } else {
                name = NSLocalizedString("Event Location", comment: "Default name for event location when none provided")
            }
            
            let address = self.formatAddress(from: placemark)
            let detailsId = UUID().uuidString
            let coordinates = location.coordinate
            
            let details = LocationDetails(
                id: detailsId,
                name: name,
                address: address,
                coordinate: coordinates
            )
            
            DispatchQueue.main.async {
                self.selectedLocation = details
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var address = ""
        
        if let thoroughfare = placemark.thoroughfare {
            address += thoroughfare
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            if !address.isEmpty {
                address += " "
            }
            address += subThoroughfare
        }
        
        if let locality = placemark.locality {
            if !address.isEmpty {
                address += ", "
            }
            address += locality
        }
        
        if let administrativeArea = placemark.administrativeArea {
            if !address.isEmpty {
                address += ", "
            }
            address += administrativeArea
        }
        
        if address.isEmpty {
            address = NSLocalizedString("Unknown Address", comment: "Default address when location cannot be determined")
        }
        
        return address
    }
    
    private func getIconForEventType(_ type: EventType) -> String {
        switch type {
        case .concert: return "music.mic"
        case .festival: return "music.note.list"
        case .rehearsal: return "pianokeys"
        case .meeting: return "person.2"
        case .interview: return "quote.bubble"
        case .photoshoot: return "camera"
        case .personal: return "person.crop.circle"
        case .birthday: return "gift"
        case .checkin: return "arrow.down.to.line"
        case .checkout: return "arrow.up.from.line"
        case .stay: return "bed.double"
        case .other: return "ellipsis.circle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func call(_ phone: String) {
        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openMail(_ email: String) {
        if let url = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openMaps(for address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func showLocationDirections(address: String, name: String) {
        NavigationService.shared.navigateToAddress(address, name: name)
    }
    
    private func hasOrganizerData() -> Bool {
        return (event.organizerName != nil && !event.organizerName!.isEmpty) ||
               (event.organizerEmail != nil && !event.organizerEmail!.isEmpty) ||
               (event.organizerPhone != nil && !event.organizerPhone!.isEmpty)
    }

    private func hasCoordinatorData() -> Bool {
        return (event.coordinatorName != nil && !event.coordinatorName!.isEmpty) ||
               (event.coordinatorEmail != nil && !event.coordinatorEmail!.isEmpty) ||
               (event.coordinatorPhone != nil && !event.coordinatorPhone!.isEmpty)
    }

    private func hasHotelData() -> Bool {
        return (event.hotelName != nil && !event.hotelName!.isEmpty) ||
               (event.hotelAddress != nil && !event.hotelAddress!.isEmpty) ||
               event.hotelCheckIn != nil ||
               event.hotelCheckOut != nil ||
               event.hotelBreakfastIncluded != nil
    }
    
    // MARK: - Link Helpers
    
    private func hasLinks(in text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        
        return !matches.isEmpty
    }
    
    // MARK: - Static Permission Check Methods
    
    private static func canEditEvent(_ event: Event) -> Bool {
        if AppState.shared.hasEditPermission(for: .calendar) {
            return true
        }
        
        if event.isPersonal,
           let currentUserId = AppState.shared.user?.id,
           event.createdBy == currentUserId {
            return true
        }
        
        return false
    }
    
    private static func canDeleteEvent(_ event: Event) -> Bool {
        if AppState.shared.hasEditPermission(for: .calendar) {
            return true
        }
        
        if event.isPersonal,
           let currentUserId = AppState.shared.user?.id,
           event.createdBy == currentUserId {
            return true
        }
        
        return false
    }
}

// MARK: - Star Rating View Component

struct StarRatingView: View {
    @Binding var rating: Int
    let isEditable: Bool
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        if isEditable {
                            rating = star
                        }
                    }
            }
        }
    }
}

// MARK: - Text With Links Component

struct TextWithLinks: View {
    let text: String
    
    var body: some View {
        if text.isEmpty {
            Text(NSLocalizedString("No Text", comment: "Message when no text content is available"))
                .italic()
                .foregroundColor(.gray)
        } else if hasLinks(in: text) {
            LinkDetectorText(text: text)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Используем обычный Text для текста без ссылок
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func hasLinks(in text: String) -> Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        return detector?.firstMatch(in: text, options: [], range: range) != nil
    }
}

struct LinkDetectorText: UIViewRepresentable {
    let text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link, .phoneNumber, .address]
        textView.font = .systemFont(ofSize: UIFont.systemFontSize)
        
        // Настройки для правильного авторазмера
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            
            // Принудительно пересчитываем размер
            DispatchQueue.main.async {
                // Рассчитываем нужную высоту для текста
                let maxWidth = uiView.frame.width > 0 ? uiView.frame.width : UIScreen.main.bounds.width - 32
                let boundingSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
                
                let textSize = text.boundingRect(
                    with: boundingSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)],
                    context: nil
                )
                
                // Устанавливаем минимальную высоту
                let finalHeight = max(textSize.height + 16, 44)
                
                // Обновляем constraint по высоте
                uiView.constraints.forEach { constraint in
                    if constraint.firstAttribute == .height {
                        constraint.constant = finalHeight
                    }
                }
                
                if uiView.constraints.isEmpty || !uiView.constraints.contains(where: { $0.firstAttribute == .height }) {
                    uiView.heightAnchor.constraint(greaterThanOrEqualToConstant: finalHeight).isActive = true
                }
                
                uiView.invalidateIntrinsicContentSize()
                uiView.superview?.setNeedsLayout()
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width - 32
        let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        
        let textSize = text.boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)],
            context: nil
        )
        
        return CGSize(width: width, height: max(textSize.height + 16, 44))
    }
}

// Extension для AppState
extension AppState {
    func hasAdminPermission() -> Bool {
        return user?.role == .admin
    }
    
    func canSeeFullEventDetails() -> Bool {
        return user?.role == .admin || user?.role == .manager
    }
    
    func canSeePersonalEvent(_ event: Event) -> Bool {
        guard let currentUserId = user?.id else {
            return false
        }
        
        if event.isPersonal {
            return event.createdBy == currentUserId
        }
        
        return true
    }
}
private func isValidURL(_ urlString: String) -> Bool {
    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
        return urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://")
    }
    return false
}
