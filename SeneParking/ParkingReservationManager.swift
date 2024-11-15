//
//  ParkingReservationManager.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 29/10/24.
//

import SwiftUI
import Combine

struct ReservationRequest: Codable {
    let parkingLotId: String
    let userId: String
    let startTime: Date
    let duration: TimeInterval
}

struct ReservationResponse: Codable {
    let reservationId: String
    let status: String
    let message: String
}

class ParkingReservationManager: ObservableObject {
    @Published var isReserving = false
    @Published var reservationStatus: ReservationStatus = .idle
    private var cancellables = Set<AnyCancellable>()
    
    enum ReservationStatus {
        case idle
        case processing
        case success(String)
        case failure(String)
    }
    
    func makeReservation(parkingLot: ParkingLot, duration: TimeInterval) {
        guard !isReserving else { return }
        isReserving = true
        reservationStatus = .processing
        
        // Simulate user ID - In a real app, this would come from authentication
        let userId = "currentUserId"
        
        let request = ReservationRequest(
            parkingLotId: parkingLot.id,
            userId: userId,
            startTime: Date(),
            duration: duration
        )
        
        // Create multiple concurrent tasks
        let availabilityCheck = checkAvailability(parkingLotId: parkingLot.id)
        let paymentValidation = validatePayment(duration: duration)
        let userValidation = validateUser(userId: userId)
        
        // Combine all validation tasks
        Publishers.CombineLatest3(availabilityCheck, paymentValidation, userValidation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isReserving = false
                    self?.reservationStatus = .failure(error.localizedDescription)
                }
            } receiveValue: { [weak self] (isAvailable, paymentValid, userValid) in
                if isAvailable && paymentValid && userValid {
                    self?.processReservation(request: request)
                } else {
                    self?.isReserving = false
                    self?.reservationStatus = .failure("Validation failed")
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAvailability(parkingLotId: String) -> AnyPublisher<Bool, Error> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                // Simulate network request
                Thread.sleep(forTimeInterval: 1)
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func validatePayment(duration: TimeInterval) -> AnyPublisher<Bool, Error> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                // Simulate payment validation
                Thread.sleep(forTimeInterval: 0.5)
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func validateUser(userId: String) -> AnyPublisher<Bool, Error> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                // Simulate user validation
                Thread.sleep(forTimeInterval: 0.3)
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func processReservation(request: ReservationRequest) {
        // Simulate API call to create reservation
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Simulate network delay
            Thread.sleep(forTimeInterval: 1)
            
            DispatchQueue.main.async {
                self?.isReserving = false
                self?.reservationStatus = .success("Reservation confirmed!")
                
                // Schedule local notification
                self?.scheduleReservationReminder(for: request.startTime)
            }
        }
    }
    
    private func scheduleReservationReminder(for date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Parking Reservation Reminder"
        content.body = "Your parking reservation starts in 15 minutes"
        content.sound = .default
        
        let triggerDate = date.addingTimeInterval(-900) // 15 minutes before
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

