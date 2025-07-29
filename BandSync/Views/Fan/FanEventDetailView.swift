import SwiftUI

struct FanEventDetailView: View {
    let fanEvent: Event
    @State private var willAttend = false
    @State private var showingLocationSheet = false
    @StateObject private var groupService = GroupService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Event Header with adaptive title and rating
                eventHeaderSection
                
                Divider()
                
                // Location section with map (not shown for birthday events)
                if fanEvent.type != .birthday {
                    locationSection
                    Divider()
                }
                
                // ✅ НОВАЯ СЕКЦИЯ: Ticket Information (для концертов и фестивалей)
                if [.concert, .festival].contains(fanEvent.type) {
                    ticketInfoSection
                    Divider()
                }
                
                // Birthday gift section (only for birthday events)
                if fanEvent.type == .birthday {
                    birthdayGiftSection
                    Divider()
                }
                
                // Attendance
                attendanceSection
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Event".localized)
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
    
    // MARK: - Event Header Section
    
    private var eventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ✅ ИСПРАВЛЕНО: Убрал GeometryReader и упростил
            Text(fanEvent.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: fanEvent.type.colorHex))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            eventTypeAndStatusRow
            
            Label(formatDate(fanEvent.date), systemImage: "calendar")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Adaptive Title Helpers
    
    private func adaptiveTitleFont(for width: CGFloat) -> Font {
        let titleLength = fanEvent.title.count
        
        // For very wide screens (iPad)
        if width > 600 {
            if titleLength > 30 {
                return .title2.bold()
            } else {
                return .largeTitle.bold()
            }
        }
        // For medium screens (iPhone Pro Max, Plus)
        else if width > 390 {
            if titleLength > 25 {
                return .title3.bold()
            } else if titleLength > 15 {
                return .title2.bold()
            } else {
                return .title.bold()
            }
        }
        // For standard screens (iPhone Pro, regular)
        else if width > 350 {
            if titleLength > 20 {
                return .headline.bold()
            } else if titleLength > 12 {
                return .title3.bold()
            } else {
                return .title2.bold()
            }
        }
        // For compact screens (iPhone Mini, SE)
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
        let titleLength = fanEvent.title.count
        
        // Approximate height based on text length
        if titleLength > 30 {
            return 100 // For very long titles (3-4 lines)
        } else if titleLength > 20 {
            return 70  // For long titles (2-3 lines)
        } else if titleLength > 10 {
            return 50  // For medium titles (1-2 lines)
        } else {
            return 35  // For short titles (1 line)
        }
    }
    
    private var eventTypeAndStatusRow: some View {
        HStack(spacing: 16) {
            Label(fanEvent.type.rawValue.localized, systemImage: fanEvent.type.icon)
                .foregroundColor(Color(hex: fanEvent.type.colorHex))
            
            Label(fanEvent.status.rawValue.localized, systemImage: "checkmark.circle")
                .foregroundColor(fanEvent.status.color)
        }
    }
    
    // MARK: - Location Section with Map
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location".localized)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Use existing EventMapView
                EventMapView(event: fanEvent)
                
                // Get directions button
                if let location = fanEvent.location, !location.isEmpty {
                    Button {
                        showLocationDirections(address: location, name: fanEvent.title)
                    } label: {
                        Label("Get directions".localized, systemImage: "arrow.triangle.turn.up.right.diamond")
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
    
    // MARK: - ✅ НОВАЯ СЕКЦИЯ: Ticket Information Section
    
    private var ticketInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ticket Information", systemImage: "ticket")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: (fanEvent.isPaidEvent ?? false) ? "creditcard.fill" : "gift.fill")
                        .foregroundColor((fanEvent.isPaidEvent ?? false) ? .orange : .green)
                    
                    Text((fanEvent.isPaidEvent ?? false) ? "Event is paid".localized : "Event is free".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor((fanEvent.isPaidEvent ?? false) ? .orange : .green)
                    
                    Spacer()
                }
                
                // Кнопка "Buy Tickets" если событие платное и есть ссылка
                if (fanEvent.isPaidEvent ?? false), let ticketUrl = fanEvent.ticketPurchaseUrl, !ticketUrl.isEmpty {
                    Button {
                        if let url = URL(string: ticketUrl) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.white)
                            Text("Buy Tickets".localized)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                } else if !(fanEvent.isPaidEvent ?? false) {
                    // Дополнительное сообщение для бесплатных событий
                    HStack {
                        Image(systemName: "party.popper")
                            .foregroundColor(.green)
                        Text("No tickets required - just come and enjoy!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Birthday Gift Section
    
    private var birthdayGiftSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Send a Gift".localized, systemImage: "gift")
                .font(.headline)
                .foregroundColor(.pink)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Want to send a birthday gift?".localized)
                    .font(.body)
                    .foregroundColor(.primary)
                
                // PayPal address from admin settings
                if groupService.isLoading {
                    // Show loading state
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading gift options...".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else if let paypalAddress = getPayPalAddressFromAdmin() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PayPal Address:".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(paypalAddress)
                                .font(.body)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = paypalAddress
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // PayPal button
                    Button(action: {
                        openPayPal(address: paypalAddress)
                    }) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Send Gift via PayPal".localized)
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                } else {
                    // If no PayPal address is set by admin
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            Text("Gift sending is currently unavailable".localized)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("The band hasn't set up gift receiving yet.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Attendance Section
    
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Different labels for birthday vs other events
            if fanEvent.type == .birthday {
                Label("Gift Status", systemImage: "gift")
                    .font(.headline)
                    .foregroundColor(.pink)
            } else {
                Label("Attendance", systemImage: "hand.raised")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                HStack {
                    // Different text for birthday vs other events
                    if fanEvent.type == .birthday {
                        Text("Gift sent".localized)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("I plan to attend this event")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $willAttend)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: fanEvent.type == .birthday ? .pink : .blue))
                }
                
                if willAttend {
                    HStack {
                        Image(systemName: fanEvent.type == .birthday ? "gift.fill" : "heart.fill")
                            .foregroundColor(fanEvent.type == .birthday ? .pink : .blue)
                        
                        if fanEvent.type == .birthday {
                            Text("Thank you for sending a gift! 🎁")
                                .font(.subheadline)
                                .foregroundColor(.pink)
                                .fontWeight(.medium)
                        } else {
                            Text("Great! We're excited to see you there!")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(willAttend ?
                   (fanEvent.type == .birthday ? Color.pink.opacity(0.1) : Color.blue.opacity(0.1)) :
                   Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func setupOnAppear() {
        // Load group data to get PayPal address
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
        // Read PayPal address from group settings
        return groupService.group?.paypalAddress
    }
    
    private func openPayPal(address: String) {
        // Create PayPal payment URL
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let birthdayPersonName = fanEvent.title.replacingOccurrences(of: "Birthday", with: "").trimmingCharacters(in: .whitespaces)
        let encodedNote = "Birthday gift for \(birthdayPersonName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // PayPal.me URL format
        let paypalURL = "https://www.paypal.me/\(encodedAddress.replacingOccurrences(of: "@", with: "").replacingOccurrences(of: ".", with: ""))"
        
        // Alternative: PayPal send money URL
        let fullPayPalURL = "https://www.paypal.com/paypalme/\(encodedAddress)?note=\(encodedNote)"
        
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
            
            presentingVC.present(activityVC, animated: true)
        }
    }
}
