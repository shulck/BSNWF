import SwiftUI

struct FanEventDetailView: View {
    let fanEvent: Event
    @State private var willAttend = false
    @State private var showingLocationSheet = false
    @State private var isUpdatingAttendance = false
    @StateObject private var groupService = GroupService.shared
    @StateObject private var fanStatsService = FanStatsService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ЦВЕТНАЯ секция только с заголовком
                coloredHeaderSection
                
                // БЕЛАЯ секция с информацией
                whiteInfoSection
                
                // Content Sections
                VStack(spacing: 24) {
                    if fanEvent.type != .birthday {
                        locationCard
                    }
                    
                    if [.concert, .festival].contains(fanEvent.type) {
                        ticketInfoCard
                    }
                    
                    if fanEvent.type == .birthday {
                        birthdayGiftCard
                    }
                    
                    attendanceCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: shareEvent) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingLocationSheet) {
            FanLocationView(event: fanEvent)
        }
        .onAppear {
            setupOnAppear()
        }
    }
    
    // MARK: - ЦВЕТНАЯ секция только с заголовком
    
    private var coloredHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Event Type Badge
            HStack(spacing: 8) {
                Image(systemName: fanEvent.type.icon)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(fanEvent.type.rawValue.localized)
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.3))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            // Event Title - АДАПТИВНЫЙ
            Text(fanEvent.title)
                .font(adaptiveTitleFont)
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .lineLimit(adaptiveTitleLineLimit)
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Основной градиент с цветом типа события
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: fanEvent.type.colorHex),
                        Color(hex: fanEvent.type.colorHex).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle pattern overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 50,
                    endRadius: 200
                )
                
                // Additional depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
    
    // MARK: - БЕЛАЯ секция с информацией
    
    private var whiteInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event type and status row
            HStack(spacing: 16) {
                Label(fanEvent.type.rawValue.localized, systemImage: fanEvent.type.icon)
                    .foregroundColor(Color(hex: fanEvent.type.colorHex))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Label(fanEvent.status.rawValue.localized, systemImage: "checkmark.circle.fill")
                    .foregroundColor(fanEvent.status.color)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Date and time
            Label(formatDate(fanEvent.date), systemImage: "calendar")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Адаптивные свойства для заголовка
    
    private var adaptiveTitleFont: Font {
        let titleLength = fanEvent.title.count
        let screenWidth = UIScreen.main.bounds.width
        
        if screenWidth < 380 { // iPhone SE, Mini
            if titleLength > 25 {
                return .title3.bold()
            } else if titleLength > 15 {
                return .title2.bold()
            } else {
                return .title.bold()
            }
        } else if screenWidth < 430 { // iPhone обычный
            if titleLength > 30 {
                return .title2.bold()
            } else if titleLength > 20 {
                return .title.bold()
            } else {
                return .largeTitle.bold()
            }
        } else { // iPhone Pro Max, iPad
            if titleLength > 35 {
                return .title.bold()
            } else if titleLength > 25 {
                return .largeTitle.bold()
            } else {
                return .largeTitle.bold()
            }
        }
    }
    
    private var adaptiveTitleLineLimit: Int {
        let titleLength = fanEvent.title.count
        let screenHeight = UIScreen.main.bounds.height
        
        if screenHeight < 700 { // Маленькие экраны
            return titleLength > 40 ? 2 : 3
        } else {
            return titleLength > 50 ? 3 : 4
        }
    }
    
    // MARK: - Location Card
    
    private var locationCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Location")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let location = fanEvent.location, !location.isEmpty {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("Location not specified")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                Spacer()
            }
            
            // Map Preview (if EventMapView exists)
            if let _ = fanEvent.location, !fanEvent.location!.isEmpty {
                EventMapView(event: fanEvent)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                if let location = fanEvent.location, !location.isEmpty {
                    // Get Directions Button
                    Button {
                        showLocationDirections(address: location, name: fanEvent.title)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Directions")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    
                    // View on Map Button
                    Button {
                        showingLocationSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("View Map")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    // MARK: - Ticket Info Card
    
    private var ticketInfoCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket Information")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text((fanEvent.isPaidEvent ?? false) ? "Paid Event" : "Free Event")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Price indicator
                ZStack {
                    Circle()
                        .fill((fanEvent.isPaidEvent ?? false) ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: (fanEvent.isPaidEvent ?? false) ? "creditcard.fill" : "gift.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor((fanEvent.isPaidEvent ?? false) ? .orange : .green)
                }
            }
            
            // Ticket status and actions
            VStack(spacing: 16) {
                if (fanEvent.isPaidEvent ?? false), let ticketUrl = fanEvent.ticketPurchaseUrl, !ticketUrl.isEmpty {
                    // Buy Tickets Button
                    Button {
                        if let url = URL(string: ticketUrl) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Buy Tickets")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .orange.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .orange.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                } else if !(fanEvent.isPaidEvent ?? false) {
                    // Free event message
                    HStack(spacing: 12) {
                        Image(systemName: "party.popper.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No tickets required!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("Just come and enjoy the event")
                                .font(.caption)
                                .foregroundColor(.green.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    // MARK: - Birthday Gift Card
    
    private var birthdayGiftCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.pink)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send a Gift")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Want to send a birthday gift?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("🎁")
                    .font(.title)
            }
            
            if groupService.isLoading {
                // Loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                    
                    Text("Loading gift options...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
            } else if let paypalAddress = getPayPalAddressFromAdmin() {
                VStack(spacing: 16) {
                    // PayPal Address Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PayPal Address")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 12) {
                            Text(paypalAddress)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = paypalAddress
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Send Gift Button
                    Button(action: {
                        openPayPal(address: paypalAddress)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Send Gift via PayPal")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .pink.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                }
            } else {
                // No PayPal setup
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gift sending unavailable")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            Text("The band hasn't set up gift receiving yet")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(24)
        .background(cardBackground)
    }
    
    // MARK: - Attendance Card (ИСПРАВЛЕННАЯ ВЕРСИЯ)
    
    private var attendanceCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill((fanEvent.type == .birthday ? Color.pink : Color.blue).opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: fanEvent.type == .birthday ? "gift.fill" : "hand.raised.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(fanEvent.type == .birthday ? .pink : .blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fanEvent.type == .birthday ? "Gift Status" : "Attendance")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(fanEvent.type == .birthday ?
                             "Mark if you've sent a gift" :
                             "Mark if you attended this event")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isUpdatingAttendance {
                    VStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Updating...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Toggle("", isOn: $willAttend)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: fanEvent.type == .birthday ? .pink : .blue))
                        .scaleEffect(1.1)
                        .disabled(isUpdatingAttendance)
                        .onChange(of: willAttend) { newValue in
                            handleAttendanceToggle(newValue)
                        }
                }
            }
            
            if willAttend {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: fanEvent.type == .birthday ? "party.popper.fill" : "heart.fill")
                            .font(.title3)
                            .foregroundColor(fanEvent.type == .birthday ? .pink : .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fanEvent.type == .birthday ?
                                 "Thank you for sending a gift!" :
                                 "Great! We're excited to see you there!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(fanEvent.type == .birthday ? .pink : .blue)
                            
                            Text(fanEvent.type == .birthday ?
                                 "Your gift means a lot 🎁" :
                                 "See you at the event! 🎉")
                                .font(.caption)
                                .foregroundColor((fanEvent.type == .birthday ? Color.pink : Color.blue).opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background((fanEvent.type == .birthday ? Color.pink : Color.blue).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((fanEvent.type == .birthday ? Color.pink : Color.blue).opacity(0.2), lineWidth: 1)
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(24)
        .background(attendanceCardBackground)
        .animation(.easeInOut(duration: 0.3), value: willAttend)
    }
    
    // MARK: - NEW: Handle Attendance Toggle
    
    private func handleAttendanceToggle(_ newValue: Bool) {
        print("🎯 Attendance toggled to: \(newValue)")
        
        // Если отмечают как посещенный и это концерт/фестиваль
        if newValue && [.concert, .festival].contains(fanEvent.type) {
            guard let user = AppState.shared.user,
                  let fanGroupId = user.fanGroupId else {
                print("❌ No user or fanGroupId found")
                // Возвращаем toggle в исходное состояние
                DispatchQueue.main.async {
                    self.willAttend = !newValue
                }
                return
            }
            
            print("🔄 Updating concert attendance for fan: \(user.id)")
            isUpdatingAttendance = true
            
            // Обновляем статистику и проверяем достижения
            fanStatsService.markConcertAttended(
                fanId: user.id,
                groupId: fanGroupId
            ) { result in
                DispatchQueue.main.async {
                    self.isUpdatingAttendance = false
                    
                    switch result {
                    case .success:
                        print("✅ Concert attendance marked successfully!")
                        // willAttend уже установлен правильно
                        
                    case .failure(let error):
                        print("❌ Failed to mark concert attendance: \(error)")
                        // Возвращаем toggle в исходное состояние
                        self.willAttend = !newValue
                    }
                }
            }
        } else {
            // Для других типов событий или снятия отметки просто обновляем UI
            print("ℹ️ Non-concert event or unmarking attendance")
        }
    }
    
    // MARK: - Computed Properties для исправления ошибки компилятора
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(colorScheme == .dark ?
                  Color(UIColor.secondarySystemGroupedBackground) :
                  Color.white)
            .shadow(
                color: colorScheme == .dark ?
                    Color.clear :
                    Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
    }
    
    private var attendanceCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(attendanceBackgroundFill)
            .overlay(attendanceBackgroundOverlay)
            .shadow(
                color: colorScheme == .dark ?
                    Color.clear :
                    Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
    }
    
    private var attendanceBackgroundFill: Color {
        if willAttend {
            let baseColor = fanEvent.type == .birthday ? Color.pink : Color.blue
            return baseColor.opacity(0.02)
        } else {
            return colorScheme == .dark ?
                Color(UIColor.secondarySystemGroupedBackground) :
                Color.white
        }
    }
    
    private var attendanceBackgroundOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(attendanceStrokeColor, lineWidth: 1)
    }
    
    private var attendanceStrokeColor: Color {
        if willAttend {
            let baseColor = fanEvent.type == .birthday ? Color.pink : Color.blue
            return baseColor.opacity(0.15)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupOnAppear() {
        if let user = AppState.shared.user,
           let fanGroupId = user.fanGroupId,
           groupService.group == nil {
            groupService.fetchGroup(by: fanGroupId)
        }
    }
    
    private func showLocationDirections(address: String, name: String) {
        NavigationService.shared.navigateToAddress(address, name: name)
    }
    
    private func getPayPalAddressFromAdmin() -> String? {
        return groupService.group?.paypalAddress
    }
    
    private func openPayPal(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let birthdayPersonName = fanEvent.title.replacingOccurrences(of: "Birthday", with: "").trimmingCharacters(in: .whitespaces)
        let encodedNote = "Birthday gift for \(birthdayPersonName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let paypalURL = "https://www.paypal.me/\(encodedAddress.replacingOccurrences(of: "@", with: "").replacingOccurrences(of: ".", with: ""))"
        
        if let url = URL(string: paypalURL) {
            UIApplication.shared.open(url)
        } else if let fallbackURL = URL(string: "https://www.paypal.com") {
            UIApplication.shared.open(fallbackURL)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shareEvent() {
        let shareText = """
        🎵 \(fanEvent.title)
        📅 \(formatDate(fanEvent.date))
        📍 \(fanEvent.location ?? "Location TBA")
        🎭 \(fanEvent.type.rawValue)
        """
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var presentingVC = rootViewController
            while let presentedVC = presentingVC.presentedViewController {
                presentingVC = presentedVC
            }
            
            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            presentingVC.present(activityVC, animated: true)
        }
    }
}
