//
//  NetworkMonitor.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 5/11/24.
//

import SwiftUI
import Network

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    @Published private(set) var lastUpdated: Date?
    private let monitor = NWPathMonitor()
    
    static let shared = NetworkMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
