import SwiftUI

struct SplashView: View {
    @StateObject private var appState = AppState.shared
    @State private var shouldCheckAuth = false
    @State private var progress: Double = 0.0
    @State private var logoScale: CGFloat = 1.0
    @State private var showProgressBar = false
    @State private var loadingText = "Initializing..."
    
    private let loadingSteps = [
        "Initializing...",
        "Loading user data...",
        "Connecting to server...",
        "Preparing interface...",
        "Almost ready..."
    ]
    
    var body: some View {
        ZStack {
            if !shouldCheckAuth {
                SplashScreenView(
                    progress: progress,
                    showProgressBar: showProgressBar,
                    loadingText: loadingText
                )
                .onAppear {
                    startLoadingSequence()
                }
            } else {
                ContentNavigationView()
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

// MARK: - Splash Screen UI Component
private struct SplashScreenView: View {
    let progress: Double
    let showProgressBar: Bool
    let loadingText: String
    
    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                LogoSection()
                
                Spacer()
                
                LoadingSection(
                    progress: progress,
                    showProgressBar: showProgressBar,
                    loadingText: loadingText
                )
                .padding(.bottom, 80)
            }
        }
    }
}

// MARK: - Logo Section Component
private struct LogoSection: View {
    var body: some View {
        VStack(spacing: 40) {
            Image("bandlogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("BandSync")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Loading Section Component
private struct LoadingSection: View {
    let progress: Double
    let showProgressBar: Bool
    let loadingText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(loadingText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(showProgressBar ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: loadingText)
            
            if showProgressBar {
                ProgressBarSection(progress: progress)
            }
        }
    }
}

// MARK: - Progress Bar Component
private struct ProgressBarSection: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
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
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .transition(.opacity)
        }
    }
}

// MARK: - Content Navigation View
private struct ContentNavigationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView()
            } else {
                UserNavigationView()
            }
        }
    }
}

// MARK: - User Navigation View
private struct UserNavigationView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if let user = appState.user {
                switch user.userType {
                case .bandMember:
                    bandMemberView(user: user)
                case .fan:
                    fanView(user: user)
                }
            } else {
                LoadingUserView()
            }
        }
    }
    
    @ViewBuilder
    private func bandMemberView(user: UserModel) -> some View {
        if user.groupId != nil {
            MainTabView()
        } else {
            GroupSelectionView()
        }
    }
    
    @ViewBuilder
    private func fanView(user: UserModel) -> some View {
        if user.fanGroupId != nil {
            FanTabView()
        } else {
            GroupSelectionView()
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
            
            Text("Loading user data...")
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
