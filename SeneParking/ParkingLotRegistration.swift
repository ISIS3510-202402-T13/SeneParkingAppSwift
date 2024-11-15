import SwiftUI

struct RegisterParkingLotView: View {
    @State private var parkingLotName: String = ""
    @State private var farePerDay: String = ""
    @State private var closeTime: String = ""
    @State private var availableSpots: String = ""
    @State private var openTime: String = ""
    @State private var longitude: String = ""
    @State private var latitude: String = ""
    @State private var availableEVSpots: String = ""
    @State private var message: String = ""
    @State private var isShowingAlert: Bool = false
    @State private var registrationSuccess: Bool = false
    
    // Error message states
    @State private var parkingLotNameError: String? = nil
    @State private var farePerDayError: String? = nil
    @State private var closeTimeError: String? = nil
    @State private var availableSpotsError: String? = nil
    @State private var openTimeError: String? = nil
    @State private var longitudeError: String? = nil
    @State private var latitudeError: String? = nil
    @State private var availableEVSpotsError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()

                ScrollView {
                    VStack {
                        Spacer()
                        
                        VStack {
                            Text("Register Your Parking Lot")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 10) {
                                FormFieldWithError(
                                    title: "Parking Lot Name",
                                    text: $parkingLotName,
                                    error: parkingLotNameError
                                ) { validateParkingLotName() }
                                
                                NumberFieldWithError(
                                    title: "Fare Per Day",
                                    text: $farePerDay,
                                    error: farePerDayError
                                ) { validateFarePerDay() }
                                
                                FormFieldWithError(
                                    title: "Open Time (e.g., 06:00am)",
                                    text: $openTime,
                                    error: openTimeError
                                ) { validateOpenTime() }
                                
                                FormFieldWithError(
                                    title: "Close Time (e.g., 10:00pm)",
                                    text: $closeTime,
                                    error: closeTimeError
                                ) { validateCloseTime() }
                                
                                NumberFieldWithError(
                                    title: "Available Spots",
                                    text: $availableSpots,
                                    error: availableSpotsError
                                ) { validateAvailableSpots() }
                                
                                FormFieldWithError(
                                    title: "Longitude",
                                    text: $longitude,
                                    error: longitudeError
                                ) { validateLongitude() }
                                
                                FormFieldWithError(
                                    title: "Latitude",
                                    text: $latitude,
                                    error: latitudeError
                                ) { validateLatitude() }
                                
                                NumberFieldWithError(
                                    title: "Available EV Spots",
                                    text: $availableEVSpots,
                                    error: availableEVSpotsError
                                ) { validateEVSpots() }
                                
                                RegisterParking {
                                    validateAndRegister()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                        
                        VStack {
                            NavigationLink(destination: LicensePlateRecognitionView()) {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 5)
                            
                            Text("Use camera to recognize license plates")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Registration Status"), message: Text(message), dismissButton: .default(Text("OK")) {
                if registrationSuccess {
                    // Navigate to main menu if registration is successful
                }
            })
        }
        .background(
            NavigationLink(destination: SignInView(), isActive: $registrationSuccess) {
                EmptyView()
            }
        )
        .onAppear(perform: clearFields)
    }
    
    private func clearFields() {
        parkingLotName = ""
        farePerDay = ""
        closeTime = ""
        availableSpots = ""
        openTime = ""
        longitude = ""
        latitude = ""
        availableEVSpots = ""
        
        // Clear error messages
        parkingLotNameError = nil
        farePerDayError = nil
        closeTimeError = nil
        availableSpotsError = nil
        openTimeError = nil
        longitudeError = nil
        latitudeError = nil
        availableEVSpotsError = nil
    }
    
    private func validateParkingLotName() -> Bool {
        if parkingLotName.isEmpty {
            parkingLotNameError = "Parking lot name cannot be empty."
            return false
        }
        parkingLotNameError = nil
        return true
    }
    
    private func validateFarePerDay() -> Bool {
        guard let fare = Int(farePerDay), fare > 0 else {
            farePerDayError = "Fare must be a valid positive number."
            return false
        }
        farePerDayError = nil
        return true
    }
    
    private func validateOpenTime() -> Bool {
        let timeFormat = #"^(0[1-9]|1[0-2]):[0-5][0-9](am|pm)$"#
        guard NSPredicate(format: "SELF MATCHES %@", timeFormat).evaluate(with: openTime) else {
            openTimeError = "Open Time must be in the format hh:mmam or hh:mmpm."
            return false
        }
        openTimeError = nil
        return true
    }
    
    private func validateCloseTime() -> Bool {
        let timeFormat = #"^(0[1-9]|1[0-2]):[0-5][0-9](am|pm)$"#
        guard NSPredicate(format: "SELF MATCHES %@", timeFormat).evaluate(with: closeTime) else {
            closeTimeError = "Close Time must be in the format hh:mmam or hh:mmpm."
            return false
        }
        closeTimeError = nil
        return true
    }
    
    private func validateAvailableSpots() -> Bool {
        guard let spots = Int(availableSpots), spots >= 0 else {
            availableSpotsError = "Available spots must be a valid non-negative number."
            return false
        }
        availableSpotsError = nil
        return true
    }
    
    private func validateLongitude() -> Bool {
        guard let longitudeValue = Double(longitude),
              -180.0 <= longitudeValue && longitudeValue <= 180.0 else {
            longitudeError = "Longitude must be a valid number between -180 and 180."
            return false
        }
        longitudeError = nil
        return true
    }
    
    private func validateLatitude() -> Bool {
        guard let latitudeValue = Double(latitude),
              -90.0 <= latitudeValue && latitudeValue <= 90.0 else {
            latitudeError = "Latitude must be a valid number between -90 and 90."
            return false
        }
        latitudeError = nil
        return true
    }
    
    private func validateEVSpots() -> Bool {
        guard let evSpots = Int(availableEVSpots), evSpots >= 0 else {
            availableEVSpotsError = "Available EV spots must be a valid non-negative number."
            return false
        }
        availableEVSpotsError = nil
        return true
    }
    
    private func validateAndRegister() {
        let isValid = validateParkingLotName() &&
                     validateFarePerDay() &&
                     validateOpenTime() &&
                     validateCloseTime() &&
                     validateAvailableSpots() &&
                     validateLongitude() &&
                     validateLatitude() &&
                     validateEVSpots()
        
        if isValid {
            registerParkingLot()
        }
    }
    
    private func registerParkingLot() {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots") else {
            message = "Invalid URL"
            isShowingAlert = true
            return
        }

        let body: [String: Any] = [
            "fields": [
                "name": ["stringValue": parkingLotName],
                "farePerDay": ["integerValue": farePerDay],
                "close_time": ["stringValue": closeTime],
                "availableSpots": ["integerValue": availableSpots],
                "open_time": ["stringValue": openTime],
                "longitude": ["doubleValue": Double(longitude) ?? 0.0],
                "latitude": ["doubleValue": Double(latitude) ?? 0.0],
                "available_ev_spots": ["integerValue": availableEVSpots]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.message = "Error: \(error.localizedDescription)"
                } else if let data = data,
                          let response = try? JSONDecoder().decode(FirestoreResponse.self, from: data) {
                    self.message = "Successfully registered parking lot!"
                    self.registrationSuccess = true
                } else {
                    self.message = "Failed to register parking lot"
                }
                self.isShowingAlert = true
            }
        }.resume()
    }
}

struct FormFieldWithError: View {
    var title: String
    @Binding var text: String
    var error: String?
    var validation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(title, text: $text)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .onChange(of: text) { newValue in
                    // Limit the input to 20 characters
                    if newValue.count > 20 {
                        text = String(newValue.prefix(20))
                    }
                    validation() // Run the validation
                }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.white)
                    .font(.footnote)
                    .padding(.leading, 5)
            }
        }
        .padding(.bottom, 5)
    }
}

struct NumberFieldWithError: View {
    var title: String
    @Binding var text: String
    var error: String?
    var validation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .onChange(of: text) { newValue in
                    // Limit the input to 20 characters
                    if newValue.count > 20 {
                        text = String(newValue.prefix(20))
                    }
                    validation() // Run the validation
                }
            
            if let error = error {
                Text(error)
                    .foregroundColor(.white)
                    .font(.footnote)
                    .padding(.leading, 5)
            }
        }
        .padding(.bottom, 5)
    }
}

struct RegisterParking: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Register Parking Lot")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.top, 20)
    }
}

struct FirestoreResponse: Decodable {
    let name: String
}

struct RegisterParkingLotView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterParkingLotView()
    }
}
