//
//  SeneParkingApp.swift
//  SeneParking
//
//  Created by Juan Pablo Hernandez Troncoso on 30/09/24.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}

@main
struct SeneParkingApp: App {
    @StateObject private var notificationManager = ParkingNotificationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SignInView()
            .onAppear
            {
                // Request notification permission when app launches
                notificationManager.requestPermission()
            }
        }
    }
}
