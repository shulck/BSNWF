import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared
    @State private var shouldCheckAuth = false

    var body: some View {
        Group {
            if !shouldCheckAuth {
                VStack {
                    Text("Loading...".localized)
                    ProgressView()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldCheckAuth = true
                    }
                }
            } else {
                if !appState.isLoggedIn {
                    LoginView()
                } else {
                    // ОБНОВЛЕННАЯ ЛОГИКА: Проверяем тип пользователя
                    NavigationDestinationView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .requireTermsAcceptance()
    }
}

// MARK: - Navigation Destination Logic
private struct NavigationDestinationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if let user = appState.user {
                // Пользователь загружен - определяем куда направить
                switch user.userType {
                case .bandMember:
                    // Участники группы
                    if user.groupId != nil {
                        MainTabView()  // Основной интерфейс группы
                    } else {
                        GroupSelectionView()  // Нужно создать/присоединиться к группе
                    }
                    
                case .fan:
                    // Фанаты
                    if user.fanGroupId != nil {
                        FanTabView()  // Интерфейс фан-клуба
                    } else {
                        GroupSelectionView()  // Нужно присоединиться к фан-клубу
                    }
                }
            } else {
                // Пользователь еще загружается
                LoadingUserView()
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
            
            Text("Loading user data...".localized)
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
