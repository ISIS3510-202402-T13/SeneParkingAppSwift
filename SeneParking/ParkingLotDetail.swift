import SwiftUI
import MapKit
import UserNotifications
import Combine

// Shared image cache
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

struct ParkingLotDetailView: View {
    @State var parkingLot: ParkingLot
    @State private var notificationEnabled = false
    @State private var hasReserved = false
    @State private var showPaymentView = false
    @State private var navigateToMainMap = false
    @State private var showingConfirmation = false
    @State private var showingTimeSelection = false
    @State private var selectedStartTime = Date()
    @State private var selectedDuration = 1
    @State private var availableSpots: Int?
    @State private var reservationErrorMessage: String?
    
    @StateObject private var notificationManager = ParkingNotificationManager.shared
    @StateObject private var reservationManager = ParkingReservationManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init(parkingLot: ParkingLot) {
        _parkingLot = State(initialValue: parkingLot)
    }
    
    private var canMakeReservation: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedStartTime)
        return networkMonitor.isConnected &&
        parkingLot.availableSpots > 0 &&
        !hasReserved &&
        weekday != 1 && // Prevent reservations on Sunday
        reservationErrorMessage == nil
    }
    
    private var reservationButtonText: String {
        if !networkMonitor.isConnected {
            return "Offline - Reservations Unavailable"
        }
        if hasReserved {
            return "Reservation Made"
        }
        return reservationManager.isReserving ? "Processing..." : "Reserve Spot"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cached AsyncImage implementation
                CachedAsyncImage(urlString: "https://firebasestorage.googleapis.com/v0/b/seneparking-f457b.firebasestorage.app/o/imagen2.jpg?alt=media&token=0237c1bf-d3f7-4727-b5c8-c4d8201e3fcc")
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(10)
                
                // Existing Buttons and Other Components
                Button(action: {
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: parkingLot.coordinate))
                    mapItem.name = parkingLot.name
                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    incrementWeekdayCounter()
                }) {
                    Text("GO")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                if !hasReserved {
                    Button(action: {
                        showingTimeSelection = true
                    }) {
                        HStack {
                            Image(systemName: "clock")
                            Text("Select Parking Time")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                if let spots = availableSpots {
                    VStack(alignment: .leading) {
                        Text("Available Spots at Selected Time")
                            .font(.headline)
                        if let errorMessage = reservationErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        } else {
                            Text("\(spots) spots available")
                                .font(.title2)
                                .foregroundColor(spots > 0 ? .green : .red)
                        }
                        
                        Text("Selected time: \(formatDate(selectedStartTime))")
                            .font(.subheadline)
                        Text("Duration: \(selectedDuration) hours")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    if spots > 0 && !hasReserved && reservationErrorMessage == nil {
                        reservationSection
                    }
                }
                
                VStack(spacing: 12) {
                    InfoRow(title: "Total Spots", value: "\(parkingLot.availableSpots)")
                    InfoRow(title: "Total Electric Car Spots", value: "\(parkingLot.availableEVSpots)")
                    InfoRow(title: "Fare per Day", value: "COP \(parkingLot.farePerDay)")
                    InfoRow(title: "Opening Hours", value: "\(parkingLot.openTime) - \(parkingLot.closeTime)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button(action: {
                    notificationEnabled.toggle()
                    if notificationEnabled {
                        toggleParkingLotNotificationView()
                    } else {
                        ParkingNotificationManager.shared.removeParkingLotNotification(for: parkingLot)
                    }
                }) {
                    HStack {
                        Image(systemName: notificationEnabled ? "bell.fill" : "bell")
                        Text(notificationEnabled ? "Notifications Enabled" : "Notify When Lot Opens")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(notificationEnabled ? Color.green : Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .navigationTitle("Parking Lot Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTimeSelection) {
            NavigationView {
                TimeSelectionView(
                    selectedStartTime: $selectedStartTime,
                    selectedDuration: $selectedDuration,
                    parkingLot: parkingLot
                )
                .navigationTitle("Select Time")
                .navigationBarItems(trailing: Button("Done") {
                    showingTimeSelection = false
                    reservationErrorMessage = nil
                    checkAvailability()
                })
            }
        }
        .navigationDestination(isPresented: $showPaymentView) {
            PaymentView(
                parkingLot: parkingLot,
                reservationDuration: TimeInterval(selectedDuration * 3600)
            )
        }
    }
    
    struct CachedAsyncImage: View {
        let urlString: String
        @State private var image: UIImage?

        var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()  // Loading indicator
                        .onAppear {
                            loadImage()
                        }
                }
            }
        }

        private func loadImage() {
            let cacheKey = NSString(string: urlString)
            
            // Check if the image is already cached
            if let cachedImage = ImageCache.shared.object(forKey: cacheKey) {
                self.image = cachedImage
                return
            }
            
            // Download and cache the image
            guard let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let downloadedImage = UIImage(data: data) {
                    ImageCache.shared.setObject(downloadedImage, forKey: cacheKey)
                    DispatchQueue.main.async {
                        self.image = downloadedImage
                    }
                }
            }.resume()
        }
    }
    
    private var reservationSection: some View {
        VStack {
            if case .success(let message) = reservationManager.reservationStatus {
                Text(message)
                    .foregroundColor(.green)
                    .padding()
                    .onAppear {
                        createReservation()
                    }
            } else if case .failure(let message) = reservationManager.reservationStatus {
                Text(message)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !hasReserved {
                Button(action: {
                    reservationManager.makeReservation(
                        parkingLot: parkingLot,
                        duration: TimeInterval(selectedDuration * 3600)
                    )
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text(reservationButtonText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        canMakeReservation && !reservationManager.isReserving
                        ? Color.blue
                        : Color.gray
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!canMakeReservation || reservationManager.isReserving)
            }
        }
    }
    
    private func checkAvailability() {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/reservations") else {
            return
        }
        
        reservationErrorMessage = nil
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedStartTime)
        
        if weekday == 1 { // Sunday = 1 in Calendar
            self.availableSpots = 0
            self.reservationErrorMessage = "Reservations are not available on Sundays"
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mma"
        
        // Get start time of reservation
        let startTimeString = dateFormatter.string(from: selectedStartTime).lowercased()
        
        // Get end time of reservation
        let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime)!
        let endTimeString = dateFormatter.string(from: endTime).lowercased()
        
        // Parse parking lot operating hours
        guard let parkingOpenTime = dateFormatter.date(from: parkingLot.openTime.lowercased()),
              let parkingCloseTime = dateFormatter.date(from: parkingLot.closeTime.lowercased()),
              let reservationStartTime = dateFormatter.date(from: startTimeString),
              let reservationEndTime = dateFormatter.date(from: endTimeString) else {
            self.reservationErrorMessage = "Error validating parking hours"
            self.availableSpots = 0
            return
        }
        
        // Compare times
        if reservationStartTime < parkingOpenTime {
            self.availableSpots = 0
            self.reservationErrorMessage = "Reservation cannot start before parking lot opens at \(parkingLot.openTime)"
            return
        }
        
        if reservationStartTime > parkingCloseTime {
            self.availableSpots = 0
            self.reservationErrorMessage = "Reservation cannot start after parking lot closes at \(parkingLot.closeTime)"
            return
        }
        
        // If we get here, the times are valid, continue with existing availability check
        let queryParams = [
            "structuredQuery": [
                "where": [
                    "compositeFilter": [
                        "op": "AND",
                        "filters": [
                            [
                                "fieldFilter": [
                                    "field": ["fieldPath": "parkingLotId"],
                                    "op": "EQUAL",
                                    "value": ["stringValue": parkingLot.id]
                                ]
                            ],
                            [
                                "fieldFilter": [
                                    "field": ["fieldPath": "startTime"],
                                    "op": "LESS_THAN",
                                    "value": ["timestampValue": ISO8601DateFormatter().string(from: endTime)]
                                ]
                            ],
                            [
                                "fieldFilter": [
                                    "field": ["fieldPath": "endTime"],
                                    "op": "GREATER_THAN",
                                    "value": ["timestampValue": ISO8601DateFormatter().string(from: selectedStartTime)]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: queryParams)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let documents = json["documents"] as? [[String: Any]] {
                    let overlappingReservations = documents.count
                    self.availableSpots = max(0, self.parkingLot.availableSpots - overlappingReservations)
                } else {
                    self.availableSpots = self.parkingLot.availableSpots
                }
            }
        }.resume()
    }
    
    private func createReservation() {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/reservations") else {
            return
        }
        
        let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime)!
        
        let reservationData: [String: Any] = [
            "fields": [
                "parkingLotId": ["stringValue": parkingLot.id],
                "startTime": ["timestampValue": ISO8601DateFormatter().string(from: selectedStartTime)],
                "endTime": ["timestampValue": ISO8601DateFormatter().string(from: endTime)],
                "userId": ["stringValue": "current-user-id"] // Replace with actual user ID when authentication is implemented
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: reservationData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if error == nil {
                    self.hasReserved = true
                    self.showPaymentView = true
                    if let currentSpots = self.availableSpots {
                        self.availableSpots = currentSpots - 1
                    }
                }
            }
        }.resume()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    func incrementWeekdayCounter() {
        // Get the current day of the week in English and capitalize it
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US") // Ensure English locale
        dateFormatter.dateFormat = "EEEE" // Full weekday name
        
        let weekday = dateFormatter.string(from: Date()) // Capitalized weekday name
        
        // Define the URL to fetch the document
        guard let fetchUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/NavigationAnalytics") else {
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
                    guard let updateUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/NavigationAnalytics?updateMask.fieldPaths=\(weekday)") else {
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
    
    func toggleParkingLotNotificationView() {
        if notificationManager.isPermissionGranted {
            notificationManager.scheduleParkingLotOpeningNotification(for: parkingLot)
        } else {
            notificationManager.requestPermission()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
        }
    }
}
