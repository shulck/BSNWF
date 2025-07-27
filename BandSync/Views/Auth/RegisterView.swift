import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showLoadingIndicator = false
    @State private var emailVerified = false

    @State private var nameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var phoneError = ""

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    if !viewModel.isEmailVerificationSent && !emailVerified {
                        Text("Create Account".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Group {
                            customStyledTextField("Full Name".localized, text: $viewModel.name)
                            customStyledTextField("Email".localized, text: $viewModel.email, keyboardType: .emailAddress)
                            customStyledSecureField("Password".localized, text: $viewModel.password)
                            customStyledTextField("Phone Number".localized, text: $viewModel.phone, keyboardType: .phonePad)
                        }

                        Button(action: {
                            hideKeyboard()
                            showLoadingIndicator = true
                            viewModel.register()
                        }) {
                            HStack {
                                if showLoadingIndicator {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Register".localized)
                                }
                            }
                            .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                        .opacity(isFormValid && !showLoadingIndicator ? 1.0 : 0.6)
                        .disabled(!isFormValid || showLoadingIndicator)

                        if showLoadingIndicator {
                            ProgressView("Sending verification email…".localized)
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                                .padding()
                        }
                    } else {
                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)

                        Text("Verification email sent".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text("Verification email sent to".localized)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text(viewModel.email)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("After verifying email".localized)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 24)

                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Login".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                        .padding(.top, 16)
                        Spacer()
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.top, -12)
                            .padding(.horizontal)
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
                .frame(maxWidth: 360)
                .shadow(radius: 10)

                Spacer()

                if !viewModel.isEmailVerificationSent && !emailVerified {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Already have account".localized)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 10)
                    }
                }
            }
            .padding()
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.isEmailVerificationSent) { oldValue, newValue in
            if newValue {
                showLoadingIndicator = false
            }
        }
        .onChange(of: viewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                emailVerified = true
            }
        }
    }

    private func isButtonEnabled() -> Bool {
        return validateFields()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func customStyledTextField(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .environment(\.colorScheme, .dark)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding()
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 1)
            )
            .foregroundColor(.white)
    }

    func customStyledSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .environment(\.colorScheme, .dark)
            .padding()
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 1)
            )
            .foregroundColor(.white)
    }

    func validateFields() -> Bool {
        nameError = viewModel.name.count >= 3 ? "" : "Name must be at least 3 characters".localized
        emailError = isValidEmail(viewModel.email) ? "" : "Invalid email address".localized
        passwordError = viewModel.password.count >= 6 ? "" : "Password must be at least 6 characters".localized
        phoneError = viewModel.phone.count >= 8 ? "" : "Enter a valid phone number".localized
        return [nameError, emailError, passwordError, phoneError].allSatisfy { $0.isEmpty }
    }

    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    private var isFormValid: Bool {
        isValidName(viewModel.name) &&
        isValidEmail(viewModel.email) &&
        isValidPassword(viewModel.password) &&
        isValidPhone(viewModel.phone)
    }
    
    private func isValidName(_ name: String) -> Bool {
        return name.count >= 3
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    private func isValidPhone(_ phone: String) -> Bool {
        return phone.count >= 8
    }
}
