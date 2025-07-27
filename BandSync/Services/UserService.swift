import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserService: ObservableObject {
    static let shared = UserService()
    @Published var currentUser: UserModel?
    @Published var users: [UserModel] = []
    
    private let db = Firestore.firestore()
    private var isCurrentlyFetching = false
    
    init() {}
    
    func fetchCurrentUser(completion: @escaping (Bool) -> Void) {
        guard !isCurrentlyFetching else {
            completion(false)
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        isCurrentlyFetching = true
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            defer {
                self?.isCurrentlyFetching = false
            }
            
            if let error = error {
                print("UserService: error loading user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let user = UserModel(
                id: data["id"] as? String ?? uid,
                email: data["email"] as? String ?? "",
                name: data["name"] as? String ?? "",
                phone: data["phone"] as? String ?? "",
                groupId: data["groupId"] as? String,
                role: UserModel.UserRole(rawValue: data["role"] as? String ?? "Member") ?? .member,
                isOnline: data["isOnline"] as? Bool,
                lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                avatarURL: data["avatarURL"] as? String,
                documentPermissions: nil, // Will be loaded separately if needed
                googleDriveEmail: data["googleDriveEmail"] as? String,
                hasGoogleDriveAccess: data["hasGoogleDriveAccess"] as? Bool
            )
            
            DispatchQueue.main.async {
                self?.currentUser = user
                completion(true)
            }
        }
    }
    
    func updateUser(_ user: UserModel, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "groupId": user.groupId ?? NSNull(),
            "role": user.role.rawValue,
            "avatarURL": user.avatarURL ?? NSNull()
        ]
        
        db.collection("users").document(user.id).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error updating user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self?.currentUser = user
                    completion(true)
                }
            }
        }
    }
    
    func fetchUsers(for groupId: String, completion: @escaping ([UserModel]) -> Void) {
        db.collection("users")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("UserService: error loading users: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                let users = snapshot?.documents.compactMap { doc -> UserModel? in
                    let data = doc.data()
                    return UserModel(
                        id: data["id"] as? String ?? doc.documentID,
                        email: data["email"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        groupId: data["groupId"] as? String,
                        role: UserModel.UserRole(rawValue: data["role"] as? String ?? "Member") ?? .member,
                        isOnline: data["isOnline"] as? Bool,
                        lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                        avatarURL: data["avatarURL"] as? String,
                        documentPermissions: nil,
                        googleDriveEmail: data["googleDriveEmail"] as? String,
                        hasGoogleDriveAccess: data["hasGoogleDriveAccess"] as? Bool
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self?.users = users
                    completion(users)
                }
            }
    }
    
    func deleteUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error deleting user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func updateUserGroup(userId: String, groupId: String?, completion: @escaping (Bool) -> Void) {
        let updateData: [String: Any] = [
            "groupId": groupId ?? NSNull()
        ]
        
        db.collection("users").document(userId).updateData(updateData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error updating user group: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func updateUserGroup(groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "NoUser", code: -1, userInfo: nil)))
            return
        }
        
        db.collection("users").document(uid).updateData([
            "groupId": groupId
        ]) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.fetchCurrentUser { _ in }
                completion(.success(()))
            }
        }
    }
    
    func fetchUsers(completion: @escaping ([UserModel]) -> Void) {
        guard let groupId = currentUser?.groupId else {
            completion([])
            return
        }
        fetchUsers(for: groupId, completion: completion)
    }
    
    func fetchUsers() {
        guard let groupId = currentUser?.groupId else {
            return
        }
        
        db.collection("users")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("UserService: error fetching users: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                let fetchedUsers = documents.compactMap { document -> UserModel? in
                    let data = document.data()
                    return UserModel(
                        id: data["id"] as? String ?? document.documentID,
                        email: data["email"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        groupId: data["groupId"] as? String,
                        role: UserModel.UserRole(rawValue: data["role"] as? String ?? "Member") ?? .member,
                        avatarURL: data["avatarURL"] as? String
                    )
                }
                
                DispatchQueue.main.async {
                    self.users = fetchedUsers
                }
            }
    }
}
