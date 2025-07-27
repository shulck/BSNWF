import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var shouldCheckAuth = false

    var body: some View {
        ZStack {
            if !shouldCheckAuth {
                LoadingScreen()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            shouldCheckAuth = true
                        }
                    }
            } else {
                MainNavigationView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .requireTermsAcceptance()
    }
}

// MARK: - Loading Screen Component
private struct LoadingScreen: View {
    var body: some View {
        VStack {
            Text(NSLocalizedString("Loading...", comment: ""))
            ProgressView()
        }
    }
}

// MARK: - Main Navigation Logic
private struct MainNavigationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView()
            } else {
                UserBasedNavigationView()
            }
        }
    }
}

// MARK: - User-Based Navigation
private struct UserBasedNavigationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if let user = appState.user {
                AuthenticatedUserView(user: user)
            } else {
                LoadingUserView()
            }
        }
    }
}

// MARK: - Authenticated User View
private struct AuthenticatedUserView: View {
    let user: UserModel
    
    var body: some View {
        Group {
            switch user.userType {
            case .bandMember:
                BandMemberNavigationView(user: user)
            case .fan:
                FanNavigationView(user: user)
            }
        }
    }
}

// MARK: - Band Member Navigation
private struct BandMemberNavigationView: View {
    let user: UserModel
    
    var body: some View {
        Group {
            if user.groupId != nil {
                MainTabView()
            } else {
                GroupSelectionView()
            }
        }
    }
}

// MARK: - Fan Navigation
private struct FanNavigationView: View {
    let user: UserModel
    
    var body: some View {
        Group {
            if user.fanGroupId != nil {
                FanTabView()
            } else {
                GroupSelectionView()
            }
        }
    }
}

// MARK: - Loading User View
private struct LoadingUserView: View {
    @EnvironmentObject private var appState: AppState
    @State private var hasAttemptedLoad = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(NSLocalizedString("Loading user data...", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if !hasAttemptedLoad {
                hasAttemptedLoad = true
                appState.loadUser()
            }
        }
    }
}
