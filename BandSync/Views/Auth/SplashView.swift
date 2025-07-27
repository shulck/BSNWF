import SwiftUI

struct SplashView: View {
    @StateObject private var appState = AppState.shared
    @State private var shouldCheckAuth = false
    @State private var progress: Double = 0.0
    @State private var logoScale: CGFloat = 1.0
    @State private var showProgressBar = false
    @State private var loadingText = "Initializing...".localized
    
    private let loadingSteps = [
        "Initializing...".localized,
        "Loading user data...".localized,
        "Connecting to server...".localized,
        "Preparing interface...".localized,
        "Almost ready...".localized
    ]
    
    var body: some View {
        Group {
            if !shouldCheckAuth {
                ZStack {
                    Image("bg")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 40) {
                            Image("bandlogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                            
                            Text("BandSync".localized)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text(loadingText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .opacity(showProgressBar ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5), value: loadingText)
                            
                            VStack(spacing: 12) {
                                if showProgressBar {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: 4)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white)
                                            .frame(width: max(20, CGFloat(progress) * (UIScreen.main.bounds.width - 80)), height: 4)
                                            .animation(.easeInOut(duration: 0.3), value: progress)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 40)
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                if showProgressBar {
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                        .transition(.opacity)
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
                .onAppear {
                    startLoadingSequence()
                }
            } else {
                // ОБНОВЛЕНО: Используем новую логику навигации
                NavigationDestinationView()
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.8), value: shouldCheckAuth)
        .requireTermsAcceptance()
    }
    
    private func startLoadingSequence() {
        navigateToContentView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showProgressBar = true
            }
            
            animateProgress()
        }
    }
    
    private func animateProgress() {
        let totalDuration: Double = 2.0
        let steps = loadingSteps.count
        let stepDuration = totalDuration / Double(steps)
        
        for i in 0..<steps {
            let delay = Double(i) * stepDuration
            let targetProgress = Double(i + 1) / Double(steps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingText = loadingSteps[i]
                }
                
                withAnimation(.easeInOut(duration: stepDuration * 0.8)) {
                    progress = targetProgress
                }
                
                if i == steps - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            shouldCheckAuth = true
                        }
                    }
                }
            }
        }
    }
    
    private func navigateToContentView() {
        withAnimation {
            AppState.shared.refreshAuthState()
        }
    }
}

// MARK: - Navigation Destination Logic (идентично ContentView)
private struct NavigationDestinationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView()
            } else {
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
}

// MARK: - Loading User View (идентично ContentView)
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

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
