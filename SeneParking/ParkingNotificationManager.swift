//
//  ParkingNotificationManager.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 28/10/24.
//

import SwiftUI
import UserNotifications
import CoreLocation

class ParkingNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = ParkingNotificationManager()
    @Published var isPermissionGranted = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationPermission()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scheduleParkingLotOpeningNotification(for parkingLot: ParkingLot) {
        // Remove any existing notifications for this parking lot
        removeParkingLotNotification(for: parkingLot)
        
        let content = UNMutableNotificationContent()
        content.title = "Parking Lot Opening Soon"
        content.body = "\(parkingLot.name) will open at \(parkingLot.openTime). Don't miss your spot!"
        content.sound = .default
        
        // Parse opening time and create date components
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        guard let openingDate = dateFormatter.date(from: parkingLot.openTime) else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: openingDate)
        
        // Create trigger for daily notification at opening time
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create unique identifier for this parking lot's notification
        let identifier = "parkingLot-\(parkingLot.id)-opening"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for \(parkingLot.name)")
            }
        }
    }
    
    func removeParkingLotNotification(for parkingLot: ParkingLot) {
        let identifier = "parkingLot-\(parkingLot.id)-opening"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap here
        completionHandler()
    }
}

// Extension to add notification functionality to ParkingLotDetailView
extension ParkingLotDetailView {
    func toggleParkingLotNotification() {
        let notificationManager = ParkingNotificationManager.shared
        
        if notificationManager.isPermissionGranted {
            notificationManager.scheduleParkingLotOpeningNotification(for: parkingLot)
        } else {
            notificationManager.requestPermission()
        }
    }
}
