import SwiftUI
import MapKit
import UserNotifications
import Combine

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
    
    @StateObject private var notificationManager = ParkingNotificationManager.shared
    @StateObject private var reservationManager = ParkingReservationManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    enum ReservationStatus: String {
        case offline = "Offline - Reservations Unavailable"
        case reserved = "Reservation Made"
        case processing = "Processing..."
        case available = "Reserve Spot"
    }

    enum NotificationState: String {
        case enabled = "Notifications Enabled"
        case disabled = "Notify When Lot Opens"
    }
    
    init(parkingLot: ParkingLot) {
        _parkingLot = State(initialValue: parkingLot)
    }
    
    private var canMakeReservation: Bool {
        networkMonitor.isConnected && parkingLot.availableSpots > 0 && !hasReserved
    }
    
    private var reservationButtonText: String {
        if !networkMonitor.isConnected {
            return ReservationStatus.offline.rawValue
        }
        if hasReserved {
            return ReservationStatus.reserved.rawValue
        }
        return reservationManager.isReserving ? ReservationStatus.processing.rawValue : ReservationStatus.available.rawValue
    }

    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: parkingLot.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [parkingLot]) { lot in
                    MapMarker(coordinate: lot.coordinate, tint: .red)
                }
                .frame(height: 200)
                .cornerRadius(10)
                
                Button(action: {
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: parkingLot.coordinate))
                    mapItem.name = parkingLot.name
                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
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
                        Text("\(spots) spots available")
                            .font(.title2)
                            .foregroundColor(spots > 0 ? .green : .red)
                            
                        Text("Selected time: \(formatDate(selectedStartTime))")
                            .font(.subheadline)
                        Text("Duration: \(selectedDuration) hours")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    if spots > 0 && !hasReserved {
                        reservationSection
                    }
                }
                
                VStack(spacing: 12) {
                    InfoRow(title: "Available Spots", value: "\(parkingLot.availableSpots)")
                    InfoRow(title: "Available Electric Car Spots", value: "\(parkingLot.availableEVSpots)")
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
                        Text(notificationEnabled ? NotificationState.enabled.rawValue : NotificationState.disabled.rawValue)
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
                TimeSelectionView(selectedStartTime: $selectedStartTime, selectedDuration: $selectedDuration)
                    .navigationTitle("Select Time")
                    .navigationBarItems(trailing: Button("Done") {
                        showingTimeSelection = false
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
        
        let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime)!
        
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
