import Foundation
import Combine
import FirebaseFirestore

final class GroupViewModel: ObservableObject {
    @Published var groupName = ""
    @Published var groupCode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var pendingMembers: [String] = []
    @Published var members: [String] = []
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func createGroup(completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = AuthService.shared.currentUserUID(), !groupName.isEmpty else {
            errorMessage = "You must specify a group name"
            completion(.failure(NSError(domain: "EmptyGroupName", code: -1, userInfo: nil)))
            return
        }
        
        isLoading = true
        
        let groupCode = UUID().uuidString.prefix(6).uppercased()
        let newGroup = GroupModel(
            name: groupName,
            code: String(groupCode),
            members: [userId],
            pendingMembers: []
        )
        
        do {
            try db.collection("groups").addDocument(from: newGroup) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error creating group: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                self.successMessage = "Group successfully created!"
                
                self.db.collection("groups")
                    .whereField("code", isEqualTo: groupCode)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            self.errorMessage = "Error getting group ID: \(error.localizedDescription)"
                            completion(.failure(error))
                            return
                        }
                        
                        if let groupId = snapshot?.documents.first?.documentID {
                            // ИСПРАВЛЕНО: Используем метод с userId параметром, который возвращает Bool
                            UserService.shared.updateUserGroup(userId: userId, groupId: groupId) { success in
                                if success {
                                    self.db.collection("users").document(userId).updateData([
                                        "role": "Admin"
                                    ]) { error in
                                        if let error = error {
                                            self.errorMessage = "Error assigning administrator: \(error.localizedDescription)"
                                            completion(.failure(error))
                                        } else {
                                            completion(.success(groupId))
                                        }
                                    }
                                } else {
                                    self.errorMessage = "Error updating user group"
                                    completion(.failure(NSError(domain: "UpdateUserError", code: -1, userInfo: nil)))
                                }
                            }
                        } else {
                            self.errorMessage = "Could not find created group"
                            completion(.failure(NSError(domain: "GroupNotFound", code: -1, userInfo: nil)))
                        }
                    }
            }
        } catch {
            isLoading = false
            errorMessage = "Error creating group: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    func joinGroup(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = AuthService.shared.currentUserUID(), !groupCode.isEmpty else {
            errorMessage = "You must specify a group code"
            completion(.failure(NSError(domain: "EmptyGroupCode", code: -1, userInfo: nil)))
            return
        }
        
        isLoading = true
        
        db.collection("groups")
            .whereField("code", isEqualTo: groupCode)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error searching for group: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    self.errorMessage = "Group with this code not found"
                    completion(.failure(NSError(domain: "GroupNotFound", code: -1, userInfo: nil)))
                    return
                }
                
                let groupId = document.documentID
                
                self.db.collection("groups").document(groupId).updateData([
                    "pendingMembers": FieldValue.arrayUnion([userId])
                ]) { error in
                    if let error = error {
                        self.errorMessage = "Error joining group: \(error.localizedDescription)"
                        completion(.failure(error))
                    } else {
                        self.successMessage = "Join request sent. Waiting for confirmation."
                        completion(.success(())) // ИСПРАВЛЕНО: правильный тип для success
                    }
                }
            }
    }
    
    func loadGroupMembers(groupId: String) {
        isLoading = true
        
        GroupService.shared.fetchGroup(by: groupId)
        
        GroupService.shared.$group
            .receive(on: DispatchQueue.main)
            .sink { [weak self] group in
                guard let self = self, let group = group else { return }
                
                self.isLoading = false
                self.members = group.members
                self.pendingMembers = group.pendingMembers
            }
            .store(in: &cancellables)
    }
}
