import SwiftUI

struct ForgotPasswordView: View {
    @State private var emailOrPhone: String = ""
    @State private var message: String? = nil
    @State private var isMessageVisible: Bool = false
    @State private var isResetLinkSent: Bool = false
    @State private var recover = false
    
    // Validation message
    @State private var inputErrorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(red: 246/255, green: 74/255, blue: 85/255)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(systemName: "key.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text("Forgot Password?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                Text("Enter your email or mobile number to reset your password")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                
                // TextField for email or mobile number
                TextField("Email or Mobile Number", text: $emailOrPhone)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 5)
                    .onChange(of: emailOrPhone) { _ in
                        validateInput()
                    }
                    .disabled(isResetLinkSent) // Disable the text field after link is sent
                
                // Error message
                ErrorTextView(errorMessage: inputErrorMessage)
                
                // Success message
                if isResetLinkSent, let successMessage = message {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.footnote)
                        .padding()
                        .background(Color.white.opacity(1)) // Background for visibility
                        .cornerRadius(8)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)
                }
                
                // Reset Password button
                if !isResetLinkSent {
                    Button(action: {
                        if validateInput() {
                            // Simulate sending the reset password link
                            message = "A reset password link has been sent to your inbox."
                            isMessageVisible = true
                            isResetLinkSent = true
                        }
                    }) {
                        Text("Reset Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                
                // Button to return to the main menu
                if isResetLinkSent {
                    Button(action: {
                        recover = true
                    }) {
                        Text("Return to Main Menu")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
            .navigationDestination(isPresented: $recover) {
                SignInView()
            }
        }
    }
    
    // Input validation function
    private func validateInput() -> Bool {
        let isValid = validateEmailOrPhone(emailOrPhone)
        inputErrorMessage = isValid ? nil : "Please enter a valid email or mobile number."
        return isValid
    }

    // Email and Phone validation function
    private func validateEmailOrPhone(_ input: String) -> Bool {
        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let phonePattern = #"^\d{10}$"#
        
        let emailRegex = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        let phoneRegex = NSPredicate(format: "SELF MATCHES %@", phonePattern)
        
        return emailRegex.evaluate(with: input) || phoneRegex.evaluate(with: input)
    }
}

// MARK: - Subviews

/// Subview for Error Messages
struct ErrorTextViewer: View {
    var errorMessage: String?
    
    var body: some View {
        Text(errorMessage ?? " ")
            .foregroundColor(.red)
            .font(.footnote)
            .padding(.bottom, 10)
            .frame(height: 10) // Ensure a consistent space even when no error
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
