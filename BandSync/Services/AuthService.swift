//
//  AuthService.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {
    }

    func registerUser(email: String, password: String, name: String, phone: String, completion: @escaping (Result<User, Error>) -> Void) {
        FirebaseManager.shared.ensureInitialized()

        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "UserMissing", code: -1, userInfo: nil)))
                return
            }

            let uid = user.uid

            let userData: [String: Any] = [
                "id": uid,
                "email": email,
                "name": name,
                "phone": phone,
                "groupId": NSNull(),
                "role": "Member",
                "avatarURL": NSNull(),
                "isOnline": true,
                "lastSeen": Timestamp(date: Date()),
                "googleDriveEmail": NSNull(),
                "hasGoogleDriveAccess": false
            ]

            self?.db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    UserDefaults.standard.set(uid, forKey: "userID")
                    FCMTokenManager.shared.setupFCM(for: uid)
                    completion(.success(user))
                }
            }
        }
    }

    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        FirebaseManager.shared.ensureInitialized()

        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                UserDefaults.standard.set(user.uid, forKey: "userID")
                FCMTokenManager.shared.setupFCM(for: user.uid)
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "LoginFailed", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed: no user returned"])))
            }
        }
    }

    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            UserDefaults.standard.removeObject(forKey: "userID")
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func getCurrentUser() -> User? {
        return auth.currentUser
    }

    func isUserLoggedIn() -> Bool {
        return auth.currentUser != nil
    }
    
    func currentUserUID() -> String? {
        return auth.currentUser?.uid
    }
}
