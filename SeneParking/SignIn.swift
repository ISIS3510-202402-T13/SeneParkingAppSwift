import SwiftUI

struct SignInView: View {
    @State private var mobileNumber: String = ""
    @State private var password: String = ""
    @State private var login = false
    @State private var showLicensePlateRecognition = false
    @State private var showRegisterParkingLot = false
    
    // Variables for validation and error handling
    @State private var mobileErrorMessage: String? = nil
    @State private var passwordErrorMessage: String? = nil
    @State private var loginErrorMessage: String? = nil
    @State private var isLoading: Bool = false
    
    // Store and track the credetials in UserDefaults (session management)
    @AppStorage("userMobileNumber") private var storedMobileNumber: String = ""
    @AppStorage("userPassword") private var storedPassword: String = ""
    
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
                        
                        ErrorTextView(errorMessage: mobileErrorMessage)
                        
                        // Password Field and Error Message
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onChange(of: password) { newValue in
                                if newValue.count > 20 {
                                    password = String(newValue.prefix(20)) // Max length for password
                                }
                                validatePassword()
                            }
                        
                        ErrorTextView(errorMessage: passwordErrorMessage)
                    }
                    
                    Group {
                        // Log in Button
                        Button(action: {
                            if validateFields() {
                                attemptLogin()
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
                        
                        if let error = loginErrorMessage {
                            Text(error)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                        }
                        
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
                        
                        NavigationLink(destination: ParkingLotOwner()) {
                            Text("I'm a Parking Lot Owner")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .navigationDestination(isPresented: $login) {
                MainMapView()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            showRegisterParkingLot = false
            // Pre-fill the mobile number if it is stored in UserDefaults (session management)
            if !storedMobileNumber.isEmpty {
                mobileNumber = storedMobileNumber
            }
            if !storedPassword.isEmpty {
                password = storedPassword
            }
        }
    }
    
    func incrementWeekdayCounter(isFirstPosition: Bool) {
        // Get the current day of the week in English and capitalize it
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEEE"
        let weekday = dateFormatter.string(from: Date()) // Current day of the week

        // URL for fetching the current data from Firestore
        guard let fetchUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SignInAnalytics") else {
            print("Invalid URL for Firebase fetch")
            return
        }

        // Fetch the current values for the day
        URLSession.shared.dataTask(with: fetchUrl) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
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
                   let arrayValues = weekdayField["arrayValue"] as? [String: Any],
                   let values = arrayValues["values"] as? [[String: Any]],
                   let firstCounterString = values[0]["integerValue"] as? String,
                   let secondCounterString = values[1]["integerValue"] as? String,
                   let firstCounter = Int(firstCounterString),
                   let secondCounter = Int(secondCounterString) {

                    // Determine which counter to update
                    let updatedFirstCounter = isFirstPosition ? firstCounter + 1 : firstCounter
                    let updatedSecondCounter = !isFirstPosition ? secondCounter + 1 : secondCounter

                    // Prepare the payload for the update
                    let payload: [String: Any] = [
                        "fields": [
                            weekday: [
                                "arrayValue": [
                                    "values": [
                                        ["integerValue": "\(updatedFirstCounter)"],
                                        ["integerValue": "\(updatedSecondCounter)"]
                                    ]
                                ]
                            ]
                        ]
                    ]

                    // URL for updating the document
                    guard let updateUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SignInAnalytics?updateMask.fieldPaths=\(weekday)") else {
                        print("Invalid URL for Firebase update")
                        return
                    }

                    // Serialize the payload to JSON
                    let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])

                    // Configure the PATCH request
                    var request = URLRequest(url: updateUrl)
                    request.httpMethod = "PATCH"
                    request.httpBody = jsonData
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Perform the update request
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("Error updating weekday counter: \(error.localizedDescription)")
                        } else {
                            print("Weekday counter updated successfully for \(weekday)")
                        }
                    }.resume()
                } else {
                    print("Error parsing current counters")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    
    // MARK: - Validation Functions
    private func validateMobileNumber() -> Bool {
        if mobileNumber.isEmpty {
            mobileErrorMessage = "Mobile number cannot be empty."
            return false
        } else if !mobileNumber.allSatisfy({ $0.isNumber }) {
            mobileErrorMessage = "Mobile number must be numeric."
            return false
        } else if mobileNumber.count != 10 {
            mobileErrorMessage = "Mobile number must be 10 digits."
            return false
        }
        mobileErrorMessage = nil
        return true
    }
    
    private func validatePassword() -> Bool {
        if password.isEmpty {
            passwordErrorMessage = "Password cannot be empty."
            return false
        } else if password.count > 20 {
            passwordErrorMessage = "Password cannot exceed 20 characters."
            return false
        } else if password.count < 8 {
            passwordErrorMessage = "Password must be at least 8 characters."
            return false
        }
        passwordErrorMessage = nil
        return true
    }
    
    private func validateFields() -> Bool {
        return validateMobileNumber() && validatePassword()
    }
    
    // MARK: - Login Function
    private func attemptLogin() {
        isLoading = true
        loginErrorMessage = nil

        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/users") else {
            loginErrorMessage = "Invalid URL."
            isLoading = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    loginErrorMessage = "Login failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    loginErrorMessage = "Server error or invalid response."
                    return
                }

                guard let data = data else {
                    loginErrorMessage = "No data received."
                    return
                }

                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let documents = result?["documents"] as? [[String: Any]] {
                        var userFound = false
                        
                        // Loop through each user document to find matching mobileNumber and password
                        for document in documents {
                            if let fields = document["fields"] as? [String: Any],
                               let mobileNumberField = (fields["mobileNumber"] as? [String: Any])?["stringValue"] as? String,
                               let passwordField = (fields["password"] as? [String: Any])?["stringValue"] as? String {
                                if mobileNumberField == mobileNumber && passwordField == password {
                                    userFound = true
                                    incrementWeekdayCounter(isFirstPosition: userFound)
                                    login = true // User authenticated, navigate to the main app view
                                    
                                    // Store mobile number in UserDefaults (session management)
                                    storedMobileNumber = mobileNumber
                                    storedPassword = password
                                    break
                                }
                            }
                        }
                        
                        if !userFound {
                            loginErrorMessage = "Invalid mobile number or password."
                            incrementWeekdayCounter(isFirstPosition: userFound)
                        }
                    } else {
                        loginErrorMessage = "No users found."
                    }
                } catch {
                    loginErrorMessage = "Failed to parse user data."
                }
            }
        }

        task.resume()
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
