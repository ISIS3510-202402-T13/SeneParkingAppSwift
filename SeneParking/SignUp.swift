import SwiftUI

struct SignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var dateOfBirth: Date = Date()
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
    
    // Additional states for loading, success, or error
    @State private var isLoading: Bool = false
    @State private var registrationError: String? = nil
    @State private var registrationSuccess: Bool = false
    
    @StateObject private var connectivityManager = NetworkMonitor.shared
    @State private var showOfflineAlert: Bool = false

    
    // Date formatter
        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter
        }
    
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
                    
                    if !connectivityManager.isConnected {
                       Text("You are currently offline")
                           .foregroundColor(.white)
                           .padding()
                           .background(Color.black.opacity(0.7))
                           .cornerRadius(10)
                    }
                    
                    TermsOfServiceView()
                    
                    if !registrationSuccess {
                        RegisterButton (firstNameError: $firstNameError,
                                        lastNameError: $lastNameError,
                                        emailError: $emailError,
                                        mobileNumberError: $mobileNumberError,
                                        dateOfBirthError: $dateOfBirthError,
                                        uniandesCodeError: $uniandesCodeError,
                                        passwordError: $passwordError) {
                            if validateAllFields() {
                                registerUser()
                            }
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                        .padding(.top, 10)
                    }

                    if let error = registrationError {
                        Text(error)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    }

                    if registrationSuccess {
                        Text("Registration successful!")
                        .foregroundColor(.green)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
        }
        .alert(isPresented: $showOfflineAlert) {
            Alert(
                title: Text("Offline Registration"),
                message: Text("Please save your new account once the internet connection is restored."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Set up network status observer
            NotificationCenter.default.addObserver(
                forName: .networkStatusChanged,
                object: nil,
                queue: .main
            ) { _ in
                if connectivityManager.isConnected {
                    processPendingRegistrations()
                }
            }
        }
    }
    
    func incrementWeekdayCounter() {
        // Get the current day of the week in English and capitalize it
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US") // Ensure English locale
        dateFormatter.dateFormat = "EEEE" // Full weekday name
        
        let weekday = dateFormatter.string(from: Date()) // Capitalized weekday name

        // Define the URL to fetch the document
        guard let fetchUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SignUpAnalytics") else {
            print("Invalid URL for Firebase fetch")
            return
        }
        
        // Fetch the current value
        URLSession.shared.dataTask(with: fetchUrl) { data, response, error in
            if let error = error {
                print("Error fetching current counter: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let fields = json["fields"] as? [String: Any],
                   let weekdayField = fields[weekday] as? [String: Any],
                   let currentValueString = weekdayField["integerValue"] as? String,
                   let currentValue = Int(currentValueString) {
                    
                    // Increment the current value by 1
                    let updatedValue = currentValue + 1
                    
                    // Define the URL with document path for updating
                    guard let updateUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SignUpAnalytics?updateMask.fieldPaths=\(weekday)") else {
                        print("Invalid URL for Firebase update")
                        return
                    }

                    // Define the request payload with updated value
                    let payload: [String: Any] = [
                        "fields": [
                            weekday: ["integerValue": "\(updatedValue)"]
                        ]
                    ]
                    
                    // Serialize payload to JSON
                    guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                        print("Error encoding JSON")
                        return
                    }
                    
                    // Configure the request
                    var request = URLRequest(url: updateUrl)
                    request.httpMethod = "PATCH"
                    request.httpBody = jsonData
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Perform the update request
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("Error updating weekday counter: \(error.localizedDescription)")
                        } else {
                            print("Weekday counter updated successfully for \(weekday) with new value: \(updatedValue)")
                        }
                    }.resume()
                    
                } else {
                    print("Error parsing current counter value")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
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
        } else if mobileNumber.count > 10 || mobileNumber.count < 10 || !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileNumberError = "Mobile number must be numeric and 10 digits."
            return false
        }
        mobileNumberError = nil
        return true
    }
    
    private func validateDateOfBirth() -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        
        if age < 16 {
            dateOfBirthError = "You must be at least 16 years old."
            return false
        }
        
        dateOfBirthError = nil
        return true
    }
        
    func validateUniandesCode() -> Bool {
        if uniandesCode.isEmpty {
            uniandesCodeError = "Uniandes code cannot be empty."
            return false
        } else if uniandesCode.count > 10 || uniandesCode.count < 6 || !uniandesCode.allSatisfy({ $0.isNumber }) {
            uniandesCodeError = "Uniandes code should be between 6 - 10 numbers."
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
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters."
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
    
    // Registration action with Firestore
        func registerUser() {
            isLoading = true
            registrationError = nil
            registrationSuccess = false
            
            let formattedDate = dateFormatter.string(from: dateOfBirth)

            // Firestore expects fields to be inside a "fields" object
                let userData: [String: Any] = [
                    "fields": [
                        "firstName": ["stringValue": firstName],
                        "lastName": ["stringValue": lastName],
                        "email": ["stringValue": email],
                        "mobileNumber": ["stringValue": mobileNumber],
                        "dateOfBirth": ["stringValue": formattedDate],
                        "uniandesCode": ["stringValue": uniandesCode],
                        "password": ["stringValue": password]
                    ]
                ]

            if !connectivityManager.isConnected {
                // Handle offline registration
                OfflineDataManager.shared.savePendingUser(userData)
                isLoading = false
                registrationError = " "
                showOfflineAlert = true
                return
            }
            
            guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/users") else {
                registrationError = "Invalid URL"
                isLoading = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: userData, options: [])
                request.httpBody = jsonData
            } catch {
                registrationError = "Failed to encode user data"
                isLoading = false
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false

                    if let error = error {
                        registrationError = "Registration failed: \(error.localizedDescription)"
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        registrationError = "Server error or invalid response."
                        return
                    }

                    registrationSuccess = true
                    
                    if registrationSuccess {
                        incrementWeekdayCounter()
                    }
                }
            }

            task.resume()
        }
    
    func processPendingRegistrations() {
          let pendingUsers = OfflineDataManager.shared.getPendingUsers()
          
          for userData in pendingUsers {
              guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/users") else {
                  continue
              }
              
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
              request.setValue("application/json", forHTTPHeaderField: "Content-Type")
              
              do {
                  let jsonData = try JSONSerialization.data(withJSONObject: userData, options: [])
                  request.httpBody = jsonData
                  
                  URLSession.shared.dataTask(with: request) { _, response, error in
                      if error == nil,
                         let httpResponse = response as? HTTPURLResponse,
                         httpResponse.statusCode == 200 {
                          DispatchQueue.main.async {
                              OfflineDataManager.shared.removePendingUser(userData)
                              showRegistrationSuccessNotification()
                          }
                      }
                  }.resume()
              } catch {
                  print("Failed to process pending registration: \(error.localizedDescription)")
              }
          }
      }
      
      // Add this function to show notification when registration is complete
      private func showRegistrationSuccessNotification() {
          let content = UNMutableNotificationContent()
          content.title = "Account Created"
          content.body = "Your account has been successfully created!"
          content.sound = .default
          
          let request = UNNotificationRequest(
              identifier: UUID().uuidString,
              content: content,
              trigger: nil
          )
          
          UNUserNotificationCenter.current().add(request)
      }
}


struct BackgroundView: View {
    var body: some View {
        Color(red: 246/255, green: 74/255, blue: 85/255)
            .ignoresSafeArea()
    }
}

struct AppLogoView: View {
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
    @Binding var dateOfBirth: Date
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
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: firstName) { newValue in
                    if newValue.count > 30 {
                        firstName = String(newValue.prefix(30)) // Limit to 30 characters
                    }
                    validateFirstName()
                }
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
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: lastName) { newValue in
                    if newValue.count > 30 {
                        lastName = String(newValue.prefix(30)) // Limit to 30 characters
                    }
                    validateLastName()
                }
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
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: email) { newValue in
                    if newValue.count > 30 {
                        email = String(newValue.prefix(30)) // Limit to 30 characters
                    }
                    validateEmail()
                }
            Text(emailError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }
    
    private func mobileNumberField() -> some View {
        VStack {
            TextField("Mobile number", text: $mobileNumber)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: mobileNumber) { newValue in
                    if newValue.count > 10 {
                        mobileNumber = String(newValue.prefix(10))
                    }
                    
                    validateMobileNumber()
                }
            Text(mobileNumberError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }

    
    private func dateOfBirthField() -> some View {
        VStack(alignment: .leading) {
            DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: dateOfBirth, perform: { _ in validateDateOfBirth() })
            HStack {
                Spacer()
                Text(dateOfBirthError ?? " ")
                    .foregroundColor(.white)
                    .font(.footnote)
                Spacer()
            }
            .frame(height: 10)
        }
    }

    
    private func uniandesCodeField() -> some View {
        VStack {
            TextField("Uniandes code", text: $uniandesCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: uniandesCode) { newValue in
                    if newValue.count > 10 {
                        uniandesCode = String(newValue.prefix(10))
                    }
                    
                    validateUniandesCode()
                }
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
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 5)
                .onChange(of: password) { newValue in
                    if newValue.count > 20 {
                        password = String(newValue.prefix(20)) // Limit to 20 characters
                    }
                    validatePassword()
                }
            Text(passwordError ?? " ")
                .foregroundColor(.white)
                .font(.footnote)
                .frame(height: 10)
        }
    }

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
            let allowedDomains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com", "icloud.com", "uniandes.edu.co"]
            
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
        } else if mobileNumber.count > 10 || mobileNumber.count < 10 || !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileNumberError = "Mobile number must be numeric and 10 digits."
            return false
        }
        mobileNumberError = nil
        return true
    }
    
    private func validateDateOfBirth() -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        
        if age < 16 {
            dateOfBirthError = "You must be at least 16 years old."
            return false
        }
        
        dateOfBirthError = nil
        return true
    }
    
    // Helper function to check for leap years
    private func isLeapYear(year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    func validateUniandesCode() -> Bool {
        if uniandesCode.isEmpty {
            uniandesCodeError = "Uniandes code cannot be empty."
            return false
        } else if uniandesCode.count > 10 || uniandesCode.count < 6 || !uniandesCode.allSatisfy({ $0.isNumber }) {
            uniandesCodeError = "Uniandes code should be between 6 - 10 numbers."
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
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters."
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
    
    @Binding var firstNameError: String?
    @Binding var lastNameError: String?
    @Binding var emailError: String?
    @Binding var mobileNumberError: String?
    @Binding var dateOfBirthError: String?
    @Binding var uniandesCodeError: String?
    @Binding var passwordError: String?
    
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
    
    func validateAllFields() -> Bool {
        firstNameError == nil &&
        lastNameError == nil &&
        emailError == nil &&
        mobileNumberError == nil &&
        dateOfBirthError == nil &&
        uniandesCodeError == nil &&
        passwordError == nil
        }
    }

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
