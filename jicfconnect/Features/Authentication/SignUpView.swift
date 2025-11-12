import SwiftUI

/// Sign up view for new user registration
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        NavigationView {
            VStack(spacing: CareSphereSpacing.lg) {
                Text("Create Account")
                    .font(CareSphereTypography.titleLarge)
                    .foregroundColor(theme.colors.onBackground)
                    .padding(.top, CareSphereSpacing.xl)

                SignUpForm(
                    fullName: $fullName,
                    email: $email,
                    password: $password,
                    confirmPassword: $confirmPassword,
                    isLoading: $isLoading,
                    isFormValid: isFormValid,
                    onSignUp: signUp
                )

                Spacer()
            }
            .background(theme.colors.background)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            #else
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            #endif
            .alert("Registration Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
            && password.count >= 6
    }

    private func signUp() {
        guard isFormValid else { return }

        Task {
            isLoading = true
            do {
                try await authService.register(
                    fullName: fullName,
                    email: email,
                    password: password
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

/// Sign up form component
struct SignUpForm: View {
    @Binding var fullName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool

    let isFormValid: Bool
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: CareSphereSpacing.md) {
            TextField("Full Name", text: $fullName)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.name)

            TextField("Email", text: $email)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.emailAddress)
                #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                #endif

            SecureField("Password", text: $password)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.newPassword)

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.newPassword)

            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(CareSphereTypography.caption)
                    .foregroundColor(CareSphereColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords do not match")
                    .font(CareSphereTypography.caption)
                    .foregroundColor(CareSphereColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            CareSphereButton(
                "Create Account",
                action: onSignUp,
                style: .primary,
                isLoading: isLoading,
                isDisabled: !isFormValid
            )
        }
        .padding(.horizontal, CareSphereSpacing.xl)
    }
}

#Preview {
    SignUpView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService())
}
