import SwiftUI
import MapKit
import UserNotifications
import Combine

struct ParkingLotDetailView: View {
    @State var parkingLot: ParkingLot
    @State var notificationEnabled = false
    @State private var hasReserved = false
    @StateObject private var notificationManager = ParkingNotificationManager.shared
    @StateObject private var reservationManager = ParkingReservationManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init(parkingLot: ParkingLot) {
           _parkingLot = State(initialValue: parkingLot)
    }
    
    private var canMakeReservation: Bool {
            networkMonitor.isConnected && parkingLot.availableSpots > 0 && !hasReserved
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
    
    // Simplified function to update spots in Firestore
    private func updateParkingLotSpots() {
       guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots/\(parkingLot.id)") else {
           return
       }
       
       let body: [String: Any] = [
           "fields": [
               "availableSpots": ["integerValue": "\(parkingLot.availableSpots)"]
           ]
       ]
       
       var request = URLRequest(url: url)
       request.httpMethod = "PATCH"
       request.addValue("application/json", forHTTPHeaderField: "Content-Type")
       request.httpBody = try? JSONSerialization.data(withJSONObject: body)
       
       URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
   }
    
    
    private var reservationSection: some View {
        VStack {
                if case .success(let message) = reservationManager.reservationStatus {
                    Text(message)
                        .foregroundColor(.green)
                        .padding()
                } else if case .failure(let message) = reservationManager.reservationStatus {
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                }
            
                Button(action: {
                    guard !hasReserved else { return }
                                   
                    reservationManager.makeReservation(parkingLot: parkingLot, duration: 3600)
                   
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                       if case .success = reservationManager.reservationStatus {
                           withAnimation {
                               hasReserved = true
                               var updatedParkingLot = parkingLot
                               updatedParkingLot.availableSpots -= 1
                               parkingLot.availableSpots -= 1
                               parkingLot = updatedParkingLot
                               updateParkingLotSpots()
                           }
                       }
                    }
                    
                    // parkingLot.availableSpots -= 1
                    // updateParkingLotSpots() // 1 hour
                }) {
                    HStack {
                        Image(systemName: hasReserved ? "checkmark.circle.fill" : "calendar.badge.plus")
                        Text(reservationButtonText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canMakeReservation ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!canMakeReservation || reservationManager.isReserving || hasReserved)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !networkMonitor.isConnected {
                       HStack {
                           Spacer()
                           OfflineIndicator()
                           Spacer()
                       }
                       .padding(.top, 8)
                   }
                Text(parkingLot.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
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
                
                // Reservation Section
                if parkingLot.availableSpots > 0
                {
                    reservationSection
                }
                
                Button(action: {
                    notificationEnabled.toggle()
                    if notificationEnabled {
                        toggleParkingLotNotification()
                    } else {
                        ParkingNotificationManager.shared.removeParkingLotNotification(for: parkingLot)
                    }
                }) {
                    HStack {
                        Image(systemName: notificationEnabled ? "bell.fill" : "bell")
                            .foregroundColor(.white)
                        Text(notificationEnabled ? "Notifications Enabled" : "Notify When Lot Opens")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(notificationEnabled ? Color.green : Color.blue)
                    .cornerRadius(10)
                }
                
                // Test button after your "GO" button
                Button(action: {
                    testRealNotification()
                }) {
                    Text("Test Opening Notification")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                
                InfoRow(title: "Available Spots", value: "\(parkingLot.availableSpots)")
                InfoRow(title: "Available Electric Car Spots", value: "\(parkingLot.availableEVSpots)")
                InfoRow(title: "Fare per Day", value: "COP \(parkingLot.farePerDay)")
                InfoRow(title: "Opening Hours", value: "\(parkingLot.openTime) - \(parkingLot.closeTime)")
            }
            .padding()
        }
        .navigationTitle("Parking Lot Details")
        .navigationBarTitleDisplayMode(.inline)
    }
        
    
    // BORRAR DESPUES DEL VIVA VOCE
    func testRealNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Parking Lot Opening Soon"
        content.body = "\(parkingLot.name) will open at \(parkingLot.openTime). Don't miss your spot!"
        content.sound = .default
        
        // Create trigger for 5 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create unique identifier for this test
        let identifier = "parkingLot-\(parkingLot.id)-test"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { success, error in
            if success {
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling test notification: \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled test notification for \(parkingLot.name)")
                    }
                }
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
