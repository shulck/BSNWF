import SwiftUI
import FirebaseAuth

// MARK: - MIXED CHAT CREATION VIEW

struct MixedChatCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var chatName = ""
    @State private var chatDescription = ""
    @State private var selectedFans: Set<String> = []
    @State private var selectedBandMembers: Set<String> = []
    @State private var searchText = ""
    @State private var isCreating = false
    @State private var showingBandMembersSection = false
    @State private var showingFansSection = true
    
    // Mock data - replace with actual services
    @State private var availableFans: [UserModel] = []
    @State private var availableBandMembers: [UserModel] = []
    
    private var filteredFans: [UserModel] {
        if searchText.isEmpty {
            return availableFans
        } else {
            return availableFans.filter { fan in
                fan.displayName.localizedCaseInsensitiveContains(searchText) ||
                (fan.fanProfile?.nickname.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var filteredBandMembers: [UserModel] {
        if searchText.isEmpty {
            return availableBandMembers
        } else {
            return availableBandMembers.filter { member in
                member.name.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var canCreateChat: Bool {
        let trimmedName = chatName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               (!selectedFans.isEmpty || !selectedBandMembers.isEmpty)
    }
    
    private var totalSelectedParticipants: Int {
        return selectedFans.count + selectedBandMembers.count + 1 // +1 for current user
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Details Section
                chatDetailsSection
                
                Divider()
                
                // Participants Section
                participantsSection
                
                Spacer()
                
                // Create Button
                createButtonSection
            }
            .navigationTitle(NSLocalizedString("bandAndFansChat", comment: "Band & Fans Chat navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadParticipants()
            }
        }
    }
    
    // MARK: - Chat Details Section
    
    private var chatDetailsSection: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(NSLocalizedString("createMixedChat", comment: "Create Mixed Chat header title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("interactiveChatBetweenBandAndFans", comment: "Interactive chat between band and fans subtitle"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Chat Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("chatName", comment: "Chat name label"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(NSLocalizedString("enterChatName", comment: "Enter chat name placeholder"), text: $chatName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Chat Description Input
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("descriptionOptional", comment: "Description (Optional) label"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(NSLocalizedString("describeChatPurpose", comment: "Describe the chat purpose placeholder"), text: $chatDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
            }
            
            // Participants Summary
            participantsSummary
        }
        .padding()
    }
    
    // MARK: - Participants Summary
    
    private var participantsSummary: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text("\(totalSelectedParticipants)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("totalParticipants", comment: "Total Participants label"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Text(String.localizedStringWithFormat(NSLocalizedString("bandMembersCount", comment: "X band members"), selectedBandMembers.count + 1))
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String.localizedStringWithFormat(NSLocalizedString("fansCount", comment: "X fans"), selectedFans.count))
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
        )
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(NSLocalizedString("searchParticipants", comment: "Search participants placeholder"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            
            // Section Toggles
            HStack(spacing: 0) {
                Button {
                    showingFansSection = true
                    showingBandMembersSection = false
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(showingFansSection ? .purple : .secondary)
                            
                            Text(String.localizedStringWithFormat(NSLocalizedString("fansWithCount", comment: "Fans (X)"), selectedFans.count))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(showingFansSection ? .purple : .secondary)
                        }
                        
                        Rectangle()
                            .fill(showingFansSection ? Color.purple : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                
                Button {
                    showingFansSection = false
                    showingBandMembersSection = true
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .foregroundColor(showingBandMembersSection ? .blue : .secondary)
                            
                            Text(String.localizedStringWithFormat(NSLocalizedString("bandWithCount", comment: "Band (X)"), selectedBandMembers.count))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(showingBandMembersSection ? .blue : .secondary)
                        }
                        
                        Rectangle()
                            .fill(showingBandMembersSection ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .background(Color.secondary.opacity(0.05))
            
            // Participants List
            List {
                if showingFansSection {
                    ForEach(filteredFans, id: \.id) { fan in
                        FanSelectionRow(
                            fan: fan,
                            isSelected: selectedFans.contains(fan.id)
                        ) {
                            if selectedFans.contains(fan.id) {
                                selectedFans.remove(fan.id)
                            } else {
                                selectedFans.insert(fan.id)
                            }
                        }
                    }
                } else if showingBandMembersSection {
                    ForEach(filteredBandMembers, id: \.id) { member in
                        BandMemberSelectionRow(
                            member: member,
                            isSelected: selectedBandMembers.contains(member.id)
                        ) {
                            if selectedBandMembers.contains(member.id) {
                                selectedBandMembers.remove(member.id)
                            } else {
                                selectedBandMembers.insert(member.id)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Create Button Section
    
    private var createButtonSection: some View {
        VStack(spacing: 12) {
            if canCreateChat {
                Button(action: createMixedChat) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.message.fill")
                        }
                        
                        Text(isCreating ? NSLocalizedString("creatingChat", comment: "Creating Chat...") : NSLocalizedString("createMixedChat", comment: "Create Mixed Chat button"))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCreating)
            } else {
                Text(getDisabledReason())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadParticipants() {
        // TODO: Load actual fans and band members from services
        // For now, using mock data
        availableFans = []
        availableBandMembers = []
    }
    
    private func createMixedChat() {
        guard let user = appState.user,
              let groupId = user.groupId else { return }
        
        isCreating = true
        
        let trimmedName = chatName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = chatDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Combine all selected participants
        var allParticipants: [String] = [user.id] // Add current user
        allParticipants.append(contentsOf: selectedFans)
        allParticipants.append(contentsOf: selectedBandMembers)
        
        fanChatService.createMixedChat(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            participants: allParticipants,
            groupId: groupId
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCreating = false
            dismiss()
        }
    }
    
    private func getDisabledReason() -> String {
        let trimmedName = chatName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return NSLocalizedString("enterChatNameRequired", comment: "Enter a chat name")
        } else if selectedFans.isEmpty && selectedBandMembers.isEmpty {
            return NSLocalizedString("selectAtLeastOneParticipant", comment: "Select at least one participant")
        } else {
            return ""
        }
    }
}

// MARK: - BAND MEMBER SELECTION ROW

struct BandMemberSelectionRow: View {
    let member: UserModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Member Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Text(String(member.name.prefix(2)).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Member Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(member.role.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        if !member.email.isEmpty {
                            Text("• \(member.email)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
