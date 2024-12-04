//
//  MyReservations.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 26/11/24.
//

import SwiftUI

struct Reservation: Identifiable, Codable {
    let id: String
    let parkingLotId: String
    let parkingLotName: String
    let startTime: Date
    let endTime: Date
    var status: ReservationStatus
    let fareAmount: Double
    
    enum ReservationStatus: String, Codable {
        case upcoming
        case active
        case completed
        case cancelled
    }
}

class ReservationViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sort reservations by status
    var upcomingReservations: [Reservation] {
        reservations.filter { $0.status == .upcoming }
    }
    
    var activeReservations: [Reservation] {
        reservations.filter { $0.status == .active }
    }
    
    var pastReservations: [Reservation] {
        reservations.filter { $0.status == .completed || $0.status == .cancelled }
    }
    
    func fetchReservations() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/reservations") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        // Async/Await with DispatchQueue.main used for UI updates
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // Parse and update reservations
                self?.parseReservations(data)
            }
        }.resume()
    }
    
    func cancelReservation(_ reservation: Reservation) {
        // Construct the URL for the specific reservation document
        let documentPath = String(reservation.id.split(separator: "/").last ?? "")
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/reservations/\(documentPath)") else {
            errorMessage = "Invalid URL"
            return
        }

        // Create the update payload
        let updateData: [String: Any] = [
            "fields": [
                "status": ["stringValue": "cancelled"],
                "parkingLotId": ["stringValue": reservation.parkingLotId],
                "parkingLotName": ["stringValue": reservation.parkingLotName],
                "startTime": ["timestampValue": ISO8601DateFormatter().string(from: reservation.startTime)],
                "endTime": ["timestampValue": ISO8601DateFormatter().string(from: reservation.endTime)],
                "fareAmount": ["doubleValue": reservation.fareAmount]
            ]
        ]

        // Configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
        } catch {
            self.errorMessage = "Failed to encode update data"
            return
        }

        // Async/Await with DispatchQueue.main used for UI updates
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    self?.errorMessage = "Failed to cancel reservation: HTTP \(httpResponse.statusCode)"
                    return
                }

                // Refresh reservations after successful cancellation
                self?.fetchReservations()
            }
        }.resume()
    }
    
    private func parseReservations(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let documents = json["documents"] as? [[String: Any]] {
                
                let dateFormatter = ISO8601DateFormatter()
                
                let reservations = documents.compactMap { document -> Reservation? in
                    guard let fields = document["fields"] as? [String: Any],
                          let parkingLotId = (fields["parkingLotId"] as? [String: Any])?["stringValue"] as? String,
                          let parkingLotName = (fields["parkingLotName"] as? [String: Any])?["stringValue"] as? String,
                          let startTimeString = (fields["startTime"] as? [String: Any])?["timestampValue"] as? String,
                          let endTimeString = (fields["endTime"] as? [String: Any])?["timestampValue"] as? String,
                          let statusString = (fields["status"] as? [String: Any])?["stringValue"] as? String,
                          let fareAmount = (fields["fareAmount"] as? [String: Any])?["doubleValue"] as? Double,
                          let startTime = dateFormatter.date(from: startTimeString),
                          let endTime = dateFormatter.date(from: endTimeString),
                          let status = Reservation.ReservationStatus(rawValue: statusString)
                    else {
                        return nil
                    }
                    
                    return Reservation(
                        id: document["name"] as? String ?? UUID().uuidString,
                        parkingLotId: parkingLotId,
                        parkingLotName: parkingLotName,
                        startTime: startTime,
                        endTime: endTime,
                        status: status,
                        fareAmount: fareAmount
                    )
                }
                
                DispatchQueue.main.async {
                    self.reservations = reservations
                }
            }
        } catch {
            print("Error parsing reservations: \(error.localizedDescription)")
        }
    }
}

struct MyReservationsView: View {
    @StateObject private var viewModel = ReservationViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if !viewModel.activeReservations.isEmpty {
                                ReservationSection(
                                    title: "Current Reservations",
                                    reservations: viewModel.activeReservations,
                                    viewModel: viewModel
                                )
                            }
                            
                            if !viewModel.upcomingReservations.isEmpty {
                                ReservationSection(
                                    title: "Upcoming Reservations",
                                    reservations: viewModel.upcomingReservations,
                                    viewModel: viewModel,
                                    allowCancellation: true
                                )
                            }
                            
                            if !viewModel.pastReservations.isEmpty {
                                ReservationSection(
                                    title: "Past Reservations",
                                    reservations: viewModel.pastReservations,
                                    viewModel: viewModel
                                )
                            }
                            
                            if viewModel.activeReservations.isEmpty &&
                               viewModel.upcomingReservations.isEmpty &&
                               viewModel.pastReservations.isEmpty {
                                EmptyStateView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Reservations")
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { ErrorAlert(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            viewModel.fetchReservations()
        }
    }
}

struct ReservationSection: View {
    let title: String
    let reservations: [Reservation]
    let viewModel: ReservationViewModel
    var allowCancellation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 12)
            
            ForEach(reservations) { reservation in
                ReservationCard(
                    reservation: reservation,
                    allowCancellation: allowCancellation,
                    onCancel: {
                        viewModel.cancelReservation(reservation)
                    }
                )
            }
        }
        .padding(.horizontal)  // Added horizontal padding
    }
}

struct ReservationCard: View {
    let reservation: Reservation
    let allowCancellation: Bool
    let onCancel: () -> Void
    @State private var showingCancelAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reservation.parkingLotName)
                .font(.title3)
                .fontWeight(.bold)
            
            Group {
                ReservationDetail(icon: "calendar", text: formatDate(reservation.startTime))
                ReservationDetail(icon: "clock", text: "\(formatTime(reservation.startTime)) - \(formatTime(reservation.endTime))")
                ReservationDetail(icon: "dollarsign.circle", text: String(format: "%.2f", reservation.fareAmount))
                ReservationDetail(icon: "info.circle", text: reservation.status.rawValue.capitalized)
            }
            
            if allowCancellation && reservation.status == .upcoming {
                Button(action: { showingCancelAlert = true }) {
                    Text("Cancel Reservation")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .alert("Cancel Reservation", isPresented: $showingCancelAlert) {
            Button("No", role: .cancel) { }
            Button("Yes, Cancel", role: .destructive) {
                onCancel()
            }
        } message: {
            Text("Are you sure you want to cancel this reservation?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReservationDetail: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black.opacity(0.7))
            Text(text)
                .foregroundColor(.black)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white.opacity(0.7))
            
            Text("No Reservations")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("When you make a parking reservation, it will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct ErrorAlert: Identifiable {
    let id = UUID()
    let message: String
}

func BackgroundColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.black : Color(red: 246/255, green: 74/255, blue: 85/255)
}

struct MyReservationsView_Previews: PreviewProvider {
    static var previews: some View {
        MyReservationsView()
    }
}
