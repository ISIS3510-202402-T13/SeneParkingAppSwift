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
                                FormField(title: "Parking Lot Name", text: $parkingLotName)
                                FormField(title: "Fare Per Day", text: $farePerDay)
                                FormField(title: "Close Time (e.g., 10:00pm)", text: $closeTime)
                                FormField(title: "Available Spots", text: $availableSpots)
                                FormField(title: "Open Time (e.g., 6:00am)", text: $openTime)
                                FormField(title: "Longitude", text: $longitude)
                                FormField(title: "Latitude", text: $latitude)
                                FormField(title: "Available EV Spots", text: $availableEVSpots)
                                
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
        .onAppear {
            // Clear all fields when the view appears
            parkingLotName = ""
            farePerDay = ""
            closeTime = ""
            availableSpots = ""
            openTime = ""
            longitude = ""
            latitude = ""
            availableEVSpots = ""
        }
    }
    
    private func validateAndRegister() {
        // Input validation
        guard !parkingLotName.isEmpty,
              !farePerDay.isEmpty,
              !closeTime.isEmpty,
              !availableSpots.isEmpty,
              !openTime.isEmpty,
              !longitude.isEmpty,
              !latitude.isEmpty,
              !availableEVSpots.isEmpty else {
            message = "Please fill in all fields."
            isShowingAlert = true
            return
        }
        
        // Check numeric values
        guard let fare = Int(farePerDay), fare > 0 else {
            message = "Fare Per Day must be a valid positive number."
            isShowingAlert = true
            return
        }
        
        guard let spots = Int(availableSpots), spots >= 0 else {
            message = "Available Spots must be a valid non-negative number."
            isShowingAlert = true
            return
        }
        
        guard let evSpots = Int(availableEVSpots), evSpots >= 0 else {
            message = "Available EV Spots must be a valid non-negative number."
            isShowingAlert = true
            return
        }

        guard let longitudeValue = Double(longitude), -180.0 <= longitudeValue && longitudeValue <= 180.0 else {
            message = "Longitude must be a valid number between -180 and 180."
            isShowingAlert = true
            return
        }

        guard let latitudeValue = Double(latitude), -90.0 <= latitudeValue && latitudeValue <= 90.0 else {
            message = "Latitude must be a valid number between -90 and 90."
            isShowingAlert = true
            return
        }
        
        // Validate open and close times format
        let timeFormat = #"^(0[1-9]|1[0-2]):[0-5][0-9](am|pm)$"#
        guard NSPredicate(format: "SELF MATCHES %@", timeFormat).evaluate(with: openTime) else {
            message = "Open Time must be in the format hh:mmam or hh:mmpm."
            isShowingAlert = true
            return
        }
        
        guard NSPredicate(format: "SELF MATCHES %@", timeFormat).evaluate(with: closeTime) else {
            message = "Close Time must be in the format hh:mmam or hh:mmpm."
            isShowingAlert = true
            return
        }

        // If all validations pass, proceed to register
        registerParkingLot()
    }
    
    func registerParkingLot() {
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
                    self.registrationSuccess = true // Update this state to trigger navigation
                } else {
                    self.message = "Failed to register parking lot"
                }
                self.isShowingAlert = true
            }
        }.resume()
    }
}

struct FormField: View {
    var title: String
    @Binding var text: String
    
    var body: some View {
        TextField(title, text: $text)
            .padding()
            .background(Color.white)
            .foregroundColor(Color.black)
            .cornerRadius(10)
            .padding(.bottom, 10)
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
