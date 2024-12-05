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
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    @Published private(set) var isConnected = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = path.status == .satisfied
                
                // Only post notification when connection is restored
                if !wasConnected && path.status == .satisfied {
                    NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
                }
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
