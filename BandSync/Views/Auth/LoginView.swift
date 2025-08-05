import SwiftUI
import LocalAuthentication
import KeychainSwift

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showForgotPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        Text(NSLocalizedString("Welcome Back 👋", comment: ""))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Group {
                            TextField(NSLocalizedString("Email", comment: ""), text: $viewModel.email)
                                .onChange(of: viewModel.email) {
                                    viewModel.errorMessage = nil
                                }
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .environment(\.colorScheme, .dark)
                                .textContentType(.username)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1))
                                .foregroundColor(.white)

                            SecureField(NSLocalizedString("Password", comment: ""), text: $viewModel.password)
                                .onChange(of: viewModel.password) {
                                    viewModel.errorMessage = nil
                                }
                                .textContentType(.password)
                                .environment(\.colorScheme, .dark)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1))
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            hideKeyboard()
                            if validateFields() {
                                viewModel.login()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text(NSLocalizedString("Login", comment: ""))
                                }
                            }
                            .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                        .opacity(isLoginEnabled ? 1.0 : 0.6)
                        .disabled(!isLoginEnabled || viewModel.isLoading)

                        Button(action: {
                            authenticateWithFaceID()
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                Text(NSLocalizedString("Sign In with Face ID", comment: ""))
                            }
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )

                        Button(NSLocalizedString("Forgot Password?", comment: "")) {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.top)
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                    .frame(maxWidth: 360)
                    .shadow(radius: 10)

                    Spacer()

                    NavigationLink(destination: RegisterView()) {
                        Text(NSLocalizedString("Don't have account", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer(minLength: 20)
                }
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .fullScreenCover(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var isLoginEnabled: Bool {
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        isValidEmail(viewModel.email)
    }

    private func authenticateWithFaceID() {
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("Login with Face ID", comment: "")) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            let keychain = KeychainSwift()
                            guard keychain.get("faceIDEnabled") == "true",
                                  let email = keychain.get("savedEmail"),
                                  let password = keychain.get("savedPassword") else {
                                viewModel.errorMessage = NSLocalizedString("No credentials stored. Please login manually first. You must log in at least once to enable Face ID.", comment: "")
                                return
                            }

                            viewModel.email = email
                            viewModel.password = password
                            viewModel.login()
                        } else {
                            viewModel.errorMessage = NSLocalizedString("Face ID authentication failed.", comment: "")
                        }
                    }
                }
            } else {
                viewModel.errorMessage = NSLocalizedString("Face ID not available on this device.", comment: "")
            }
        }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func validateFields() -> Bool {
        if viewModel.email.isEmpty {
            viewModel.errorMessage = NSLocalizedString("Email cannot be empty.", comment: "")
            return false
        }
        if viewModel.password.isEmpty {
            viewModel.errorMessage = NSLocalizedString("Password cannot be empty.", comment: "")
            return false
        }
        if !isValidEmail(viewModel.email) {
            viewModel.errorMessage = NSLocalizedString("Invalid email format.", comment: "")
            return false
        }
        viewModel.errorMessage = nil
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}
