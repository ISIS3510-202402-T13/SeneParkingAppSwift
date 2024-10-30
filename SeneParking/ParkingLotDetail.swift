import SwiftUI
import MapKit
import UserNotifications
import Combine

struct ParkingLotDetailView: View {
    let parkingLot: ParkingLot
    @State private var notificationEnabled = false
    @StateObject private var notificationManager = ParkingNotificationManager.shared
    @StateObject private var reservationManager = ParkingReservationManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
    
    // Reservation Section View
    private var reservationSection: some View
    {
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
                reservationManager.makeReservation(parkingLot: parkingLot, duration: 3600) // 1 hour
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text(reservationManager.isReserving ? "Processing..." : "Reserve Spot")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(reservationManager.isReserving ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(reservationManager.isReserving)
        }
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
