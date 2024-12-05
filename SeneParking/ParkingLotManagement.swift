import SwiftUI

struct ParkingLotManagementView: View {
    var parkingLotID: String
    @State private var parkingLotData: ParkingLotData? = nil
    @State private var availableSpots: Int = 0
    @State private var availableEVSpots: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isSaving = false
    @State private var showSaveConfirmation = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()
                ScrollView {
                    
                    if !networkMonitor.isConnected {
                       HStack {
                           Image(systemName: "wifi.slash")
                           Text("You are currently offline")
                           Spacer()
                       }
                       .foregroundColor(.white)
                       .padding()
                       .background(Color.black.opacity(0.7))
                       .cornerRadius(10)
                       .padding()
                   }
                    
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
                                .padding(.bottom, 10)
                            
                            Group {
                                infoRow(label: "Name:", value: data.name)
                                infoRow(label: "Location:", value: "\(data.latitude), \(data.longitude)")
                                infoRow(label: "Open Time:", value: data.openTime)
                                infoRow(label: "Close Time:", value: data.closeTime)
                                infoRow(label: "Fare Per Day:", value: "$\(data.farePerDay)")
                            }
                            
                            Spacer()
                            
                            // Modify Available Spots
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Available Spots")
                                    .foregroundColor(.white)
                                TextField("Available Spots", value: $availableSpots, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            // Modify EV Spots
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Available Electic Vehicle Spots")
                                    .foregroundColor(.white)
                                TextField("Available Electic Vehicle Spots", value: $availableEVSpots, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            Spacer()
                            
                            // Save Changes Button
                            Button(action: saveChanges) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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
                            
                            // Save Confirmation Message
                            if showSaveConfirmation {
                                
                                if showOfflineAlert
                                {
                                    Text("Your changes will be saved when internet connection is restored")
                                    .foregroundColor(.green)
                                    .padding(.top, 10)
                                }
                                else
                                {
                                    Text("Changes saved successfully!")
                                    .foregroundColor(.green)
                                    .padding(.top, 10)
                                }
                            }
                            
                            Spacer()
                            
                            // Sign Out Button
                            NavigationLink(destination: SignInView()) {
                                Text("Sign Out")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding()
                    }
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
                }
                .onAppear {
                    fetchParkingLotData()
                }
                .navigationBarHidden(true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { _ in
               if networkMonitor.isConnected {
                   print("Network connection restored, syncing pending updates...")
                   syncPendingUpdates()
               }
           }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        
        dismissKeyboard()
        
        if !networkMonitor.isConnected {
            // Save offline
            let update = OfflineUpdate(
                parkingLotId: parkingLotID,
                availableSpots: availableSpots,
                availableEVSpots: availableEVSpots
            )
            OfflineUpdateManager.shared.savePendingUpdate(update)
            
            // Show offline alert and confirmation
            showOfflineAlert = true
            showSaveConfirmation = true
            
            // Reset states after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isSaving = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSaveConfirmation = false
                }
            }
            return
        }
    
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
                
                showSaveConfirmation = true
                
                // Hide confirmation after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSaveConfirmation = false
                }
            }
        }.resume()
    }
    
    // Helper for info rows
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
                .fontWeight(.bold)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
    private func syncPendingUpdates() {
            let updates = OfflineUpdateManager.shared.getPendingUpdates()
            print("Found \(updates.count) pending updates to sync")

            
            for update in updates {
                guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots/\(update.parkingLotId)?updateMask.fieldPaths=availableSpots&updateMask.fieldPaths=available_ev_spots") else {
                    continue
                }
                
                let updatedData: [String: Any] = [
                    "fields": [
                        "availableSpots": ["integerValue": "\(update.availableSpots)"],
                        "available_ev_spots": ["integerValue": "\(update.availableEVSpots)"]
                    ]
                ]
                
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: updatedData)
                
                URLSession.shared.dataTask(with: request) { _, response, error in
                                DispatchQueue.main.async {
                                    if let httpResponse = response as? HTTPURLResponse,
                                       (200...299).contains(httpResponse.statusCode) {
                                        print("Successfully synced update for parking lot: \(update.parkingLotId)")
                                        OfflineUpdateManager.shared.removePendingUpdate(forId: update.parkingLotId)
                                        
                                        // Update the UI to reflect the synced changes
                                        showSaveConfirmation = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showSaveConfirmation = false
                                        }
                                    } else {
                                        print("Failed to sync update: \(error?.localizedDescription ?? "Unknown error")")
                                    }
                                }
                            }.resume()
            }
        }
}


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

// For eventual connectivity: save changes locally and push them to DB when connection is restored
struct OfflineUpdate: Codable {
    let parkingLotId: String
    let availableSpots: Int
    let availableEVSpots: Int
}

class OfflineUpdateManager {
    static let shared = OfflineUpdateManager()
    private let userDefaults = UserDefaults.standard
    private let pendingUpdatesKey = "pendingParkingUpdates"
    
    func savePendingUpdate(_ update: OfflineUpdate) {
        var updates = getPendingUpdates()
        // Replace existing update for same parking lot if exists
        updates.removeAll { $0.parkingLotId == update.parkingLotId }
        updates.append(update)
        
        if let encoded = try? JSONEncoder().encode(updates) {
            userDefaults.set(encoded, forKey: pendingUpdatesKey)
        }
    }
    
    func getPendingUpdates() -> [OfflineUpdate] {
        guard let data = userDefaults.data(forKey: pendingUpdatesKey),
              let updates = try? JSONDecoder().decode([OfflineUpdate].self, from: data) else {
            return []
        }
        return updates
    }
    
    func removePendingUpdate(forId: String) {
        var updates = getPendingUpdates()
        updates.removeAll { $0.parkingLotId == forId }
        if let encoded = try? JSONEncoder().encode(updates) {
            userDefaults.set(encoded, forKey: pendingUpdatesKey)
        }
    }
}
