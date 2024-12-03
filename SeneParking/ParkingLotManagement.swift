import SwiftUI

struct ParkingLotManagementView: View {
    var parkingLotID: String
    @State private var parkingLotData: ParkingLotData? = nil
    @State private var availableSpots: Int = 0
    @State private var availableEVSpots: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                        .foregroundColor(.white)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if let data = parkingLotData {
                    VStack(spacing: 20) {
                        Text("Manage Parking Lot")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Group {
                            Text("Name: \(data.name)")
                            Text("Location: \(data.latitude), \(data.longitude)")
                            Text("Open Time: \(data.openTime)")
                            Text("Close Time: \(data.closeTime)")
                            Text("Fare Per Day: $\(data.farePerDay)")
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Modify Available Spots
                        HStack {
                            Text("Available Spots:")
                                .foregroundColor(.white)
                            TextField("Available Spots", value: $availableSpots, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: 100)
                        }
                        
                        // Modify EV Spots
                        HStack {
                            Text("EV Spots:")
                                .foregroundColor(.white)
                            TextField("Available EV Spots", value: $availableEVSpots, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: 100)
                        }
                        
                        Spacer()
                        
                        // Save Changes Button
                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 20)
                            } else {
                                Text("Save Changes")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .onAppear {
                fetchParkingLotData()
            }
            .navigationBarHidden(true)
        }
    }
    
    // Fetch Parking Lot Data
    private func fetchParkingLotData() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots/\(parkingLotID)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
            
                do {
                    let decodedData = try JSONDecoder().decode(FirestoreDocument.self, from: data)
                    let fields = decodedData.fields
                    self.parkingLotData = ParkingLotData(
                        name: fields.name.stringValue,
                        latitude: fields.latitude.doubleValue,
                        longitude: fields.longitude.doubleValue,
                        openTime: fields.open_time.stringValue,
                        closeTime: fields.close_time.stringValue,
                        farePerDay: Int(fields.farePerDay.integerValue) ?? 0,
                        availableSpots: Int(fields.availableSpots.integerValue) ?? 0,
                        availableEVSpots: Int(fields.available_ev_spots.integerValue) ?? 0
                    )
                    self.availableSpots = self.parkingLotData!.availableSpots
                    self.availableEVSpots = self.parkingLotData!.availableEVSpots
                } catch {
                    errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // Save Changes
    private func saveChanges() {
        guard let data = parkingLotData else { return }
        isSaving = true
        errorMessage = nil
        
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots/\(parkingLotID)?updateMask.fieldPaths=availableSpots&updateMask.fieldPaths=available_ev_spots") else {
            errorMessage = "Invalid URL"
            isSaving = false
            return
        }
        
        let updatedData: [String: Any] = [
            "fields": [
                "availableSpots": ["integerValue": "\(availableSpots)"],
                "available_ev_spots": ["integerValue": "\(availableEVSpots)"]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: updatedData, options: [])
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSaving = false
                
                if let error = error {
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    errorMessage = "Failed to save changes. Please try again."
                    return
                }
                
                errorMessage = "Changes saved successfully!"
            }
        }.resume()
    }
}

// MARK: - Models

struct ParkingLotData {
    let name: String
    let latitude: Double
    let longitude: Double
    let openTime: String
    let closeTime: String
    let farePerDay: Int
    let availableSpots: Int
    let availableEVSpots: Int
}

struct FirestoreDocument: Decodable {
    let fields: Fields
}

struct Fields: Decodable {
    let name: FirestoreStringValue
    let latitude: FirestoreDoubleValue
    let longitude: FirestoreDoubleValue
    let open_time: FirestoreStringValue
    let close_time: FirestoreStringValue
    let farePerDay: FirestoreIntegerValue
    let availableSpots: FirestoreIntegerValue
    let available_ev_spots: FirestoreIntegerValue
}

struct FirestoreStringValue: Decodable { let stringValue: String }
struct FirestoreDoubleValue: Decodable { let doubleValue: Double }
struct FirestoreIntegerValue: Decodable { let integerValue: String }
