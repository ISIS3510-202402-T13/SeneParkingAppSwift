import SwiftUI

struct SignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var dateOfBirth: String = ""
    @State private var uniandesCode: String = ""
    @State private var password: String = ""
    
    // Error messages
    @State private var firstNameError: String? = nil
    @State private var lastNameError: String? = nil
    @State private var emailError: String? = nil
    @State private var mobileNumberError: String? = nil
    @State private var dateOfBirthError: String? = nil
    @State private var uniandesCodeError: String? = nil
    @State private var passwordError: String? = nil
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            ScrollView {
                VStack {
                    Spacer()
                    
                    AppLogoView()
                    
                    FormFields(
                        firstName: $firstName,
                        lastName: $lastName,
                        email: $email,
                        mobileNumber: $mobileNumber,
                        dateOfBirth: $dateOfBirth,
                        uniandesCode: $uniandesCode,
                        password: $password,
                        firstNameError: $firstNameError,
                        lastNameError: $lastNameError,
                        emailError: $emailError,
                        mobileNumberError: $mobileNumberError,
                        dateOfBirthError: $dateOfBirthError,
                        uniandesCodeError: $uniandesCodeError,
                        passwordError: $passwordError
                    )
                    
                    TermsOfServiceView()
                    
                    RegisterButton {
                        if validateAllFields() {
                            // Add registration action here
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    // Validation Functions
    func validateFirstName() -> Bool {
        if firstName.isEmpty {
            firstNameError = "First name cannot be empty."
            return false
        }
        firstNameError = nil
        return true
    }
    
    func validateLastName() -> Bool {
        if lastName.isEmpty {
            lastNameError = "Last name cannot be empty."
            return false
        }
        lastNameError = nil
        return true
    }
    
    func validateEmail() -> Bool {
        if email.isEmpty {
            emailError = "Email cannot be empty."
            return false
        } else if !email.contains("@") {
            emailError = "Invalid email format."
            return false
        }
        emailError = nil
        return true
    }
    
    func validateMobileNumber() -> Bool {
        if mobileNumber.isEmpty {
            mobileNumberError = "Mobile number cannot be empty."
            return false
        } else if mobileNumber.count > 10 || !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileNumberError = "Mobile number must be numeric and max 10 digits."
            return false
        }
        mobileNumberError = nil
        return true
    }
    
    func validateDateOfBirth() -> Bool {
        if dateOfBirth.isEmpty {
            dateOfBirthError = "Date of birth cannot be empty."
            return false
        }
        dateOfBirthError = nil
        return true
    }
    
    func validateUniandesCode() -> Bool {
        if uniandesCode.isEmpty {
            uniandesCodeError = "Uniandes code cannot be empty."
            return false
        }
        uniandesCodeError = nil
        return true
    }
    
    func validatePassword() -> Bool {
        if password.isEmpty {
            passwordError = "Password cannot be empty."
            return false
        } else if password.count > 30 {
            passwordError = "Password cannot exceed 30 characters."
            return false
        }
        passwordError = nil
        return true
    }
    
    func validateAllFields() -> Bool {
        return validateFirstName() &&
               validateLastName() &&
               validateEmail() &&
               validateMobileNumber() &&
               validateDateOfBirth() &&
               validateUniandesCode() &&
               validatePassword()
    }
}

struct BackgroundView: View {
    var body: some View {
        Color(red: 246/255, green: 74/255, blue: 85/255)
            .ignoresSafeArea()
    }
}

struct AppLogoView: View { // Renamed from LogoView to AppLogoView
    var body: some View {
        VStack {
            Image(systemName: "car.fill") // TODO
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("SeneParking")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("Register")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            Text("Please enter your information to create an account")
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 20)
        }
    }
}

struct FormFields: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var email: String
    @Binding var mobileNumber: String
    @Binding var dateOfBirth: String
    @Binding var uniandesCode: String
    @Binding var password: String
    
    @Binding var firstNameError: String?
    @Binding var lastNameError: String?
    @Binding var emailError: String?
    @Binding var mobileNumberError: String?
    @Binding var dateOfBirthError: String?
    @Binding var uniandesCodeError: String?
    @Binding var passwordError: String?
    
    var body: some View {
        VStack {
            Group {
                firstNameField()
                lastNameField()
                emailField()
                mobileNumberField()
                dateOfBirthField()
                uniandesCodeField()
                passwordField()
            }
        }
    }
    
    private func firstNameField() -> some View {
        VStack {
            TextField("First name", text: $firstName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: firstName, perform: { _ in validateFirstName() })
            Text(firstNameError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func lastNameField() -> some View {
        VStack {
            TextField("Last name", text: $lastName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: lastName, perform: { _ in validateLastName() })
            Text(lastNameError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func emailField() -> some View {
        VStack {
            TextField("Email", text: $email)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: email, perform: { _ in validateEmail() })
            Text(emailError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func mobileNumberField() -> some View {
        VStack {
            TextField("Mobile number", text: $mobileNumber)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: mobileNumber, perform: { _ in validateMobileNumber() })
            Text(mobileNumberError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func dateOfBirthField() -> some View {
        VStack {
            TextField("Date of birth", text: $dateOfBirth)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: dateOfBirth, perform: { _ in validateDateOfBirth() })
            Text(dateOfBirthError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func uniandesCodeField() -> some View {
        VStack {
            TextField("Uniandes code", text: $uniandesCode)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: uniandesCode, perform: { _ in validateUniandesCode() })
            Text(uniandesCodeError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func passwordField() -> some View {
        VStack {
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: password, perform: { _ in validatePassword() })
            Text(passwordError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }

    // Validation Functions (You can define them here or pass them down from SignUpView)
    private func validateFirstName() -> Bool {
        if firstName.isEmpty {
            firstNameError = "First name cannot be empty."
            return false
        }
        firstNameError = nil
        return true
    }
    
    private func validateLastName() -> Bool {
        if lastName.isEmpty {
            lastNameError = "Last name cannot be empty."
            return false
        }
        lastNameError = nil
        return true
    }
    
    private func validateEmail() -> Bool {
        if email.isEmpty {
            emailError = "Email cannot be empty."
            return false
        } else if !email.contains("@") {
            emailError = "Invalid email format."
            return false
        } else {
            // Regular expression for email format
            let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            let regex = NSPredicate(format: "SELF MATCHES %@", emailPattern)
            
            if !regex.evaluate(with: email) {
                emailError = "Invalid email format."
                return false
            }
            
            // Check for allowed domains
            let allowedDomains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com"]
            
            guard let domain = email.split(separator: "@").last?.lowercased() else {
                emailError = "Invalid email domain."
                return false
            }
            
            if !allowedDomains.contains(String(domain)) {
                emailError = "Email domain not allowed."
                return false
            }
        }
        
        emailError = nil
        return true
    }
    
    private func validateMobileNumber() -> Bool {
        if mobileNumber.isEmpty {
            mobileNumberError = "Mobile number cannot be empty."
            return false
        } else if mobileNumber.count > 10 || !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileNumberError = "Mobile number must be numeric and max 10 digits."
            return false
        }
        mobileNumberError = nil
        return true
    }
    
    private func validateDateOfBirth() -> Bool {
        let datePattern = #"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$"#
        let regex = NSPredicate(format: "SELF MATCHES %@", datePattern)
        
        if dateOfBirth.isEmpty {
            dateOfBirthError = "Date of birth cannot be empty."
            return false
        } else if !regex.evaluate(with: dateOfBirth) {
            dateOfBirthError = "Date of birth must be in the format dd/mm/yyyy."
            return false
        } else {
            let components = dateOfBirth.split(separator: "/").map { Int($0) }
            guard let day = components[0], let month = components[1], let year = components[2] else {
                dateOfBirthError = "Invalid date."
                return false
            }
            
            // Check for valid date values
            if day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 {
                dateOfBirthError = "Invalid date values."
                return false
            }
            
            // Check for days in month
            if (month == 2 && day > 29) || (month == 2 && day == 29 && !isLeapYear(year: year)) {
                dateOfBirthError = "February has at most 28 days."
                return false
            }
            
            if (month == 4 || month == 6 || month == 9 || month == 11) && day > 30 {
                dateOfBirthError = "This month has at most 30 days."
                return false
            }
        }
        
        dateOfBirthError = nil
        return true
    }

    // Helper function to check for leap years
    private func isLeapYear(year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    private func validateUniandesCode() -> Bool {
        if uniandesCode.isEmpty {
            uniandesCodeError = "Uniandes code cannot be empty."
            return false
        }
        uniandesCodeError = nil
        return true
    }
    
    private func validatePassword() -> Bool {
        if password.isEmpty {
            passwordError = "Password cannot be empty."
            return false
        } else if password.count > 30 {
            passwordError = "Password cannot exceed 30 characters."
            return false
        }
        passwordError = nil
        return true
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
            .font(.footnote)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.bottom, 30)
    }
}

struct RegisterButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 10)
        }
        .disabled(!validateAllFields()) // Disable if validation fails
    }
    
    // Example validation function to be replaced with actual logic
    func validateAllFields() -> Bool {
        return true
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
