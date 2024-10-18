import SwiftUI

struct SignInView: View {
    @State private var mobileNumber: String = ""
    @State private var password: String = ""
    @State private var login = false
    
    // Variables for validation
    @State private var mobileErrorMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    LogoView() // Subview for Logo and App Title
                    
                    Group {
                        // Mobile Number / ID Field and Error Message
                        TextField("Mobile number or university ID", text: $mobileNumber)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onChange(of: mobileNumber) { _ in
                                validateMobileNumber()
                            }
                        
                        ErrorTextView(errorMessage: mobileErrorMessage)
                        
                        // Password Field and Error Message
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onChange(of: password) { _ in
                                validatePassword()
                            }
                        
                        ErrorTextView(errorMessage: passwordErrorMessage)
                    }
                    
                    Group {
                        // Log in Button
                        Button(action: {
                            if validateFields() {
                                login = true
                            }
                        }) {
                            Text("Log in")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 10)
                        .disabled(!validateFields()) // Disable the button if fields are invalid
                        
                        // Forgot Password Link
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot password?")
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                        }
                        
                        // Create Account Link
                        NavigationLink(destination: SignUpView()) {
                            Text("Create new account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .navigationDestination(isPresented: $login) {
                MainMapView()
            }
        }
    }
    
    // MARK: - Validation Functions
    private func validateMobileNumber() -> Bool {
        if mobileNumber.isEmpty {
            mobileErrorMessage = "Mobile number or ID cannot be empty."
            return false
        } else if !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileErrorMessage = "Mobile number or ID must be numeric."
            return false
        } else if mobileNumber.count > 10 {
            mobileErrorMessage = "Mobile number or ID cannot exceed 10 digits."
            return false
        }
        mobileErrorMessage = nil
        return true
    }
    
    private func validatePassword() -> Bool {
        if password.isEmpty {
            passwordErrorMessage = "Password cannot be empty."
            return false
        } else if password.count > 30 {
            passwordErrorMessage = "Password cannot exceed 30 characters."
            return false
        }
        passwordErrorMessage = nil
        return true
    }
    
    private func validateFields() -> Bool {
        return validateMobileNumber() && validatePassword()
    }
}

// MARK: - Subviews

/// Subview for Logo and App Title
struct LogoView: View {
    var body: some View {
        VStack {
            Image(systemName: "car.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("SeneParking")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 20)
        }
    }
}

/// Subview for Error Messages
struct ErrorTextView: View {
    var errorMessage: String?
    
    var body: some View {
        Text(errorMessage ?? " ")
            .foregroundColor(.white)
            .font(.footnote)
            .padding(.bottom, 10)
            .frame(height: 10) // Ensure a consistent space even when no error
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
