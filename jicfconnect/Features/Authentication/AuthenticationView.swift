import SwiftUI

/// Main authentication view with sign in form
struct AuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var theme: CareSphereTheme

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingSignUp = false

    var body: some View {
        VStack(spacing: CareSphereSpacing.xl) {
            Spacer()

            // Logo and title
            LogoHeader()

            Spacer()

            // Sign in form
            SignInForm(
                email: $email,
                password: $password,
                isLoading: $isLoading,
                onSignIn: signIn,
                onShowSignUp: { showingSignUp = true }
            )

            Spacer()
        }
        .background(theme.colors.background)
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }

        Task {
            isLoading = true
            do {
                try await authService.login(email: email, password: password)
            } catch {
                // Handle error (show alert, etc.)
                print("Login failed: \(error)")
            }
            isLoading = false
        }
    }
}

/// Reusable logo header component
struct LogoHeader: View {
    @EnvironmentObject private var theme: CareSphereTheme

    var body: some View {
        VStack(spacing: CareSphereSpacing.lg) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.colors.primary)

            Text("CareSphere")
                .font(CareSphereTypography.displayMedium)
                .foregroundColor(theme.colors.onBackground)

            Text("Connect, Care, Community")
                .font(CareSphereTypography.bodyLarge)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
        }
    }
}

/// Sign in form component
struct SignInForm: View {
    @EnvironmentObject private var theme: CareSphereTheme

    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool

    let onSignIn: () -> Void
    let onShowSignUp: () -> Void

    var body: some View {
        VStack(spacing: CareSphereSpacing.md) {
            TextField("Email", text: $email)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.emailAddress)
                #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                #endif

            SecureField("Password", text: $password)
                .textFieldStyle(CareSphereTextFieldStyle())
                .textContentType(.password)

            CareSphereButton(
                "Sign In",
                action: onSignIn,
                style: .primary,
                isLoading: isLoading,
                isDisabled: email.isEmpty || password.isEmpty
            )

            Button("Don't have an account? Sign up") {
                onShowSignUp()
            }
            .font(CareSphereTypography.bodyMedium)
            .foregroundColor(theme.colors.primary)
        }
        .padding(.horizontal, CareSphereSpacing.xl)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(CareSphereTheme.shared)
        .environmentObject(AuthenticationService())
}
