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
                } else if appState.user?.groupId != nil {
                    MainTabView()
                } else {
                    GroupSelectionView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .requireTermsAcceptance()
    }
}
