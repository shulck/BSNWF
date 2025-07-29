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

    private func fetchGroupMembers(groupId: String, completion: @escaping (Bool) -> Void) {
        guard let group = self.group else {
            completion(false)
            return
        }
        
        // Clear arrays on main queue
        DispatchQueue.main.async {
            self.groupMembers = []
            self.pendingMembers = []
        }
        
        let totalRequests = group.members.count + group.pendingMembers.count
        
        if totalRequests == 0 {
            completion(true)
            return
        }
        
        var completedRequests = 0
        let completionQueue = DispatchQueue(label: "groupservice.completion", attributes: .concurrent)
        
        func checkCompletion() {
            completionQueue.sync {
                completedRequests += 1
                
                if completedRequests == totalRequests {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            }
        }
        
        // Fetch members
        for memberId in group.members {
            db.collection("users").document(memberId).getDocument { [weak self] snapshot, error in
                defer { checkCompletion() }
                
                if let userData = try? snapshot?.data(as: UserModel.self) {
                    DispatchQueue.main.async {
                        // Check if user is not already in the array
                        if !(self?.groupMembers.contains(where: { $0.id == userData.id }) ?? false) {
                            self?.groupMembers.append(userData)
                        }
                    }
                }
            }
        }
        
        // Fetch pending members
        for pendingId in group.pendingMembers {
            db.collection("users").document(pendingId).getDocument { [weak self] snapshot, error in
                defer { checkCompletion() }
                
                if let userData = try? snapshot?.data(as: UserModel.self) {
                    DispatchQueue.main.async {
                        self?.pendingMembers.append(userData)
                    }
                }
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
                    // Remove from local pending members array
                    if let pendingIndex = self?.pendingMembers.firstIndex(where: { $0.id == userId }) {
                        self?.pendingMembers.remove(at: pendingIndex)
                    }
                }
            }
            
            // Update user's group ID (outside main queue to avoid blocking)
            self?.db.collection("users").document(userId).updateData([
                "groupId": NSNull()
            ])
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
                    // Remove from local members array
                    if let memberIndex = self?.groupMembers.firstIndex(where: { $0.id == userId }) {
                        self?.groupMembers.remove(at: memberIndex)
                    }
                }
            }
            
            // Update user's group ID (outside main queue to avoid blocking)
            self?.db.collection("users").document(userId).updateData([
                "groupId": NSNull()
            ])
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
            "paypalAddress": paypalAddress.isEmpty ? nil : paypalAddress
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
                    // Update local array
                    if let memberIndex = self?.groupMembers.firstIndex(where: { $0.id == userId }) {
                        var updatedMember = self?.groupMembers[memberIndex]
                        updatedMember?.role = newRole
                        if let updatedMember = updatedMember {
                            self?.groupMembers[memberIndex] = updatedMember
                        }
                    }
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
            "description": group.description ?? NSNull()
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
