import Foundation
import FirebaseFirestore

final class GroupService: ObservableObject {
    static let shared = GroupService()

    @Published var group: GroupModel?
    @Published var groupMembers: [UserModel] = []
    @Published var pendingMembers: [UserModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    
    func fetchGroup(by id: String, completion: @escaping (Bool) -> Void = { _ in }) {
        // Update loading state on main queue
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("groups").document(id).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Handle errors on main queue
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error loading group: \(error.localizedDescription)"
                    self.isLoading = false
                }
                completion(false)
                return
            }
            
            // Process data and update on main queue
            if let data = try? snapshot?.data(as: GroupModel.self) {
                DispatchQueue.main.async {
                    self.group = data
                    self.isLoading = false
                }
                completion(true)
            } else {
                // ✅ ОБНОВЛЕНО: Ручной парсинг для совместимости с Firebase
                if let data = snapshot?.data() {
                    let group = self.parseGroupFromFirebase(data, id: id)
                    DispatchQueue.main.async {
                        self.group = group
                        self.isLoading = false
                    }
                    completion(true)
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Group not found"
                        self.isLoading = false
                    }
                    completion(false)
                }
            }
        }
    }
    
    // ✅ НОВЫЙ: Парсинг группы из Firebase данных
    private func parseGroupFromFirebase(_ data: [String: Any], id: String) -> GroupModel {
        return GroupModel(
            id: id,
            name: data["name"] as? String ?? "",
            code: data["code"] as? String ?? "",
            members: data["members"] as? [String] ?? [],
            pendingMembers: data["pendingMembers"] as? [String] ?? [],
            logoURL: data["logoURL"] as? String,
            description: data["description"] as? String,
            paypalAddress: data["paypalAddress"] as? String,
            establishedDate: data["establishedDate"] as? String,
            genre: data["genre"] as? String,
            location: data["location"] as? String,
            socialMediaLinks: parseSocialMediaLinks(from: data["socialMediaLinks"]),
            admins: data["admins"] as? [String],
            membersCount: data["membersCount"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            createdBy: data["createdBy"] as? String
        )
    }
    
    // ✅ НОВЫЙ: Парсинг социальных сетей
    private func parseSocialMediaLinks(from data: Any?) -> SocialMediaLinks? {
        guard let socialDict = data as? [String: Any] else { return nil }
        
        return SocialMediaLinks(
            website: socialDict["website"] as? String,
            facebook: socialDict["facebook"] as? String,
            instagram: socialDict["instagram"] as? String,
            youtube: socialDict["youtube"] as? String,
            spotify: socialDict["spotify"] as? String,
            appleMusic: socialDict["appleMusic"] as? String,
            twitter: socialDict["twitter"] as? String,
            tiktok: socialDict["tiktok"] as? String,
            soundcloud: socialDict["soundcloud"] as? String,
            bandcamp: socialDict["bandcamp"] as? String,
            patreon: socialDict["patreon"] as? String,
            discord: socialDict["discord"] as? String,
            linkedin: socialDict["linkedin"] as? String,
            pinterest: socialDict["pinterest"] as? String,
            snapchat: socialDict["snapchat"] as? String,
            telegram: socialDict["telegram"] as? String,
            whatsapp: socialDict["whatsapp"] as? String,
            reddit: socialDict["reddit"] as? String
        )
    }
    
    func fetchGroupMembers() {
        guard let groupId = group?.id else { return }
        
        UserService.shared.fetchUsers(for: groupId) { [weak self] users in
            DispatchQueue.main.async {
                self?.groupMembers = users.filter { $0.groupId == groupId }
                self?.pendingMembers = [] // Calculate pending separately if needed
            }
        }
    }
    
    func approveUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard let groupId = group?.id else {
            completion(false)
            return
        }
        
        // Remove from pending and add to members
        var updatedGroup = group!
        updatedGroup.pendingMembers.removeAll { $0 == userId }
        updatedGroup.members.append(userId)
        
        // Update user's groupId
        UserService.shared.updateUserGroup(userId: userId, groupId: groupId) { [weak self] success in
            if success {
                self?.updateGroup(updatedGroup) { success in
                    completion(success)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func rejectUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard var updatedGroup = group else {
            completion(false)
            return
        }
        
        updatedGroup.pendingMembers.removeAll { $0 == userId }
        
        updateGroup(updatedGroup) { success in
            completion(success)
        }
    }
    
    func removeUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        guard var updatedGroup = group else {
            completion(false)
            return
        }
        
        updatedGroup.members.removeAll { $0 == userId }
        
        // Clear user's groupId
        UserService.shared.updateUserGroup(userId: userId, groupId: nil) { [weak self] success in
            if success {
                self?.updateGroup(updatedGroup) { success in
                    completion(success)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func changeUserRole(userId: String, newRole: UserModel.UserRole, completion: @escaping (Bool) -> Void) {
        let roleUpdateData: [String: Any] = [
            "role": newRole.rawValue
        ]
        
        db.collection("users").document(userId).updateData(roleUpdateData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Error updating user role: \(error.localizedDescription)"
                    completion(false)
                } else {
                    // Update local data
                    if let memberIndex = self?.groupMembers.firstIndex(where: { $0.id == userId }) {
                        var updatedMember = self?.groupMembers[memberIndex]
                        updatedMember?.role = newRole
                        self?.groupMembers[memberIndex] = updatedMember!
                    }
                    completion(true)
                }
            }
        }
    }
    
    func regenerateCode() {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let newCode = UUID().uuidString.prefix(6).uppercased()

        db.collection("groups").document(groupId).updateData([
            "code": String(newCode)
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating code: \(error.localizedDescription)"
                } else {
                    self?.group?.code = String(newCode)
                }
            }
        }
    }
    
    func updateGroupName(_ newName: String) {
        guard let groupId = group?.id else { return }
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("groups").document(groupId).updateData([
            "name": newName
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating name: \(error.localizedDescription)"
                } else {
                    self?.group?.name = newName
                }
            }
        }
    }
    
    func updatePayPalAddress(_ paypalAddress: String) {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("groups").document(groupId).updateData([
            "paypalAddress": paypalAddress.isEmpty ? NSNull() : paypalAddress
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating PayPal address: \(error.localizedDescription)"
                } else {
                    self?.group?.paypalAddress = paypalAddress.isEmpty ? nil : paypalAddress
                }
            }
        }
    }
    
    // ✅ НОВЫЙ: Обновление дополнительной информации о группе
    func updateGroupDetails(
        description: String?,
        establishedDate: String?,
        genre: String?,
        location: String?,
        socialMediaLinks: SocialMediaLinks?
    ) {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        var updateData: [String: Any] = [:]
        
        // Основная информация
        updateData["description"] = description?.isEmpty == false ? description : NSNull()
        updateData["establishedDate"] = establishedDate?.isEmpty == false ? establishedDate : NSNull()
        updateData["genre"] = genre?.isEmpty == false ? genre : NSNull()
        updateData["location"] = location?.isEmpty == false ? location : NSNull()
        
        // Социальные сети
        if let socialMedia = socialMediaLinks, !socialMedia.isEmpty {
            var socialDict: [String: Any] = [:]
            
            if let website = socialMedia.website, !website.isEmpty { socialDict["website"] = website }
            if let facebook = socialMedia.facebook, !facebook.isEmpty { socialDict["facebook"] = facebook }
            if let instagram = socialMedia.instagram, !instagram.isEmpty { socialDict["instagram"] = instagram }
            if let youtube = socialMedia.youtube, !youtube.isEmpty { socialDict["youtube"] = youtube }
            if let spotify = socialMedia.spotify, !spotify.isEmpty { socialDict["spotify"] = spotify }
            if let appleMusic = socialMedia.appleMusic, !appleMusic.isEmpty { socialDict["appleMusic"] = appleMusic }
            if let twitter = socialMedia.twitter, !twitter.isEmpty { socialDict["twitter"] = twitter }
            if let tiktok = socialMedia.tiktok, !tiktok.isEmpty { socialDict["tiktok"] = tiktok }
            if let soundcloud = socialMedia.soundcloud, !soundcloud.isEmpty { socialDict["soundcloud"] = soundcloud }
            if let bandcamp = socialMedia.bandcamp, !bandcamp.isEmpty { socialDict["bandcamp"] = bandcamp }
            if let patreon = socialMedia.patreon, !patreon.isEmpty { socialDict["patreon"] = patreon }
            if let discord = socialMedia.discord, !discord.isEmpty { socialDict["discord"] = discord }
            if let linkedin = socialMedia.linkedin, !linkedin.isEmpty { socialDict["linkedin"] = linkedin }
            if let pinterest = socialMedia.pinterest, !pinterest.isEmpty { socialDict["pinterest"] = pinterest }
            if let snapchat = socialMedia.snapchat, !snapchat.isEmpty { socialDict["snapchat"] = snapchat }
            if let telegram = socialMedia.telegram, !telegram.isEmpty { socialDict["telegram"] = telegram }
            if let whatsapp = socialMedia.whatsapp, !whatsapp.isEmpty { socialDict["whatsapp"] = whatsapp }
            if let reddit = socialMedia.reddit, !reddit.isEmpty { socialDict["reddit"] = reddit }
            
            updateData["socialMediaLinks"] = socialDict.isEmpty ? NSNull() : socialDict
        } else {
            updateData["socialMediaLinks"] = NSNull()
        }
        
        db.collection("groups").document(groupId).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating group details: \(error.localizedDescription)"
                } else {
                    // Обновляем локальные данные
                    self?.group?.description = description
                    self?.group?.establishedDate = establishedDate
                    self?.group?.genre = genre
                    self?.group?.location = location
                    self?.group?.socialMediaLinks = socialMediaLinks
                }
            }
        }
    }
    
    func updateGroup(_ group: GroupModel, completion: @escaping (Bool) -> Void) {
        guard let groupId = group.id else {
            completion(false)
            return
        }
        
        let groupData: [String: Any] = [
            "name": group.name,
            "code": group.code,
            "members": group.members,
            "pendingMembers": group.pendingMembers,
            "logoURL": group.logoURL ?? NSNull(),
            "description": group.description ?? NSNull(),
            "paypalAddress": group.paypalAddress ?? NSNull(),
            "establishedDate": group.establishedDate ?? NSNull(),
            "genre": group.genre ?? NSNull(),
            "location": group.location ?? NSNull()
        ]
        
        db.collection("groups").document(groupId).updateData(groupData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("GroupService: error updating group: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self?.group = group
                    completion(true)
                }
            }
        }
    }
}
