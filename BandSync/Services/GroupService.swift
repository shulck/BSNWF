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
                }
                
                // ИСПРАВЛЕНО: Используем новый метод UserService вместо старого fetchGroupMembers
                self.fetchGroupMembers(groupId: id) { success in
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    completion(success)
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Error converting group data"
                    self.isLoading = false
                }
                completion(false)
            }
        }
    }

    // ИСПРАВЛЕНО: Новый метод использует UserService.fetchUsers() для загрузки всех пользователей
    private func fetchGroupMembers(groupId: String, completion: @escaping (Bool) -> Void) {
        guard let group = self.group else {
            completion(false)
            return
        }
        
        print("GroupService: Loading members for group: \(groupId)")
        print("GroupService: Group has \(group.members.count) members and \(group.pendingMembers.count) pending")
        
        // Clear arrays on main queue
        DispatchQueue.main.async {
            self.groupMembers = []
            self.pendingMembers = []
        }
        
        // НОВАЯ ЛОГИКА: Используем UserService.fetchUsers() для загрузки всех пользователей группы
        UserService.shared.fetchUsers(for: groupId) { [weak self] allUsers in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("GroupService: UserService returned \(allUsers.count) users")
                
                // Разделяем пользователей на утвержденных и ожидающих
                let approvedMembers = allUsers.filter { user in
                    group.members.contains(user.id)
                }
                
                let pendingUsers = allUsers.filter { user in
                    group.pendingMembers.contains(user.id)
                }
                
                print("GroupService: Approved members: \(approvedMembers.count)")
                print("GroupService: Pending members: \(pendingUsers.count)")
                
                self.groupMembers = approvedMembers
                self.pendingMembers = pendingUsers
                
                completion(true)
            }
        }
    }

    func approveUser(userId: String) {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }

        db.collection("groups").document(groupId).updateData([
            "pendingMembers": FieldValue.arrayRemove([userId]),
            "members": FieldValue.arrayUnion([userId])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Error approving user: \(error.localizedDescription)"
                } else {
                    // Update user's group ID
                    self?.db.collection("users").document(userId).updateData([
                        "groupId": groupId
                    ]) { _ in
                        // Refresh members after updating user
                        self?.fetchGroupMembers(groupId: groupId) { _ in }
                    }
                }
            }
        }
    }

    func rejectUser(userId: String) {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("groups").document(groupId).updateData([
            "pendingMembers": FieldValue.arrayRemove([userId])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Error rejecting user: \(error.localizedDescription)"
                } else {
                    // Refresh members after updating
                    self?.fetchGroupMembers(groupId: groupId) { _ in }
                }
            }
        }
    }

    func removeUser(userId: String) {
        guard let groupId = group?.id else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("groups").document(groupId).updateData([
            "members": FieldValue.arrayRemove([userId])
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Error removing user: \(error.localizedDescription)"
                } else {
                    // Remove user's group ID
                    self?.db.collection("users").document(userId).updateData([
                        "groupId": NSNull()
                    ]) { _ in
                        // Refresh members after updating
                        self?.fetchGroupMembers(groupId: groupId) { _ in }
                    }
                }
            }
        }
    }

    func changeUserRole(userId: String, newRole: UserModel.UserRole) {
        guard !userId.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Error: Empty user ID"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        db.collection("users").document(userId).updateData([
            "role": newRole.rawValue
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error changing role: \(error.localizedDescription)"
                } else {
                    // Update local data
                    if let self = self,
                       let memberIndex = self.groupMembers.firstIndex(where: { $0.id == userId }) {
                        var updatedMember = self.groupMembers[memberIndex]
                        updatedMember.role = newRole
                        self.groupMembers[memberIndex] = updatedMember
                    }
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
            "paypalAddress": group.paypalAddress ?? NSNull()
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
