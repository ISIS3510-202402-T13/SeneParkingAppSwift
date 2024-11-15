//
//  OfflineDataManager.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 5/11/24.
//

import Foundation

class OfflineDataManager {
    static let shared = OfflineDataManager()
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let pendingUsersKey = "pendingUsers"
    private let lastUpdateTimeKey = "lastUpdateTime"
    private let cachedParkingLotsKey = "cachedParkingLots"
    
    // Save pending user registration
    func savePendingUser(_ userData: [String: Any]) {
        var pendingUsers = getPendingUsers()
        pendingUsers.append(userData)
        userDefaults.set(pendingUsers, forKey: pendingUsersKey)
    }
    
    // Get all pending user registrations
    func getPendingUsers() -> [[String: Any]] {
        return userDefaults.array(forKey: pendingUsersKey) as? [[String: Any]] ?? []
    }
    
    // Remove pending user after successful upload
    func removePendingUser(_ userData: [String: Any]) {
        var pendingUsers = getPendingUsers()
        pendingUsers.removeAll { $0["email"] as? String == userData["email"] as? String }
        userDefaults.set(pendingUsers, forKey: pendingUsersKey)
    }
    
    // Save last update time
    func saveLastUpdateTime() {
        userDefaults.set(Date(), forKey: lastUpdateTimeKey)
    }
    
    // Get last update time
    func getLastUpdateTime() -> Date? {
        return userDefaults.object(forKey: lastUpdateTimeKey) as? Date
    }
    
    // Cache parking lots data
    func cacheParkingLots(_ parkingLots: [ParkingLot]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(parkingLots) {
            userDefaults.set(encoded, forKey: cachedParkingLotsKey)
            saveLastUpdateTime()
        }
    }
    
    // Get cached parking lots
    func getCachedParkingLots() -> [ParkingLot]? {
        if let data = userDefaults.data(forKey: cachedParkingLotsKey) {
            let decoder = JSONDecoder()
            return try? decoder.decode([ParkingLot].self, from: data)
        }
        return nil
    }
}
