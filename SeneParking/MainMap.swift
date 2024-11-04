//
//  MainMap.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 2/10/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct ParkingLot: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let availableSpots: Int
    let availableEVSpots: Int
    let farePerDay: Int
    let openTime: String
    let closeTime: String
}

struct MainMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showEVOnly = false
    @State private var parkingLots: [ParkingLot] = []
    @State private var cachedParkingLots: [ParkingLot] = [] // Cache variable
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6015, longitude: -74.0655),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var filteredParkingLots: [ParkingLot] {
        showEVOnly ? parkingLots.filter { $0.availableEVSpots > 0 } : parkingLots
    }

    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: filteredParkingLots) { lot in
                    MapAnnotation(coordinate: lot.coordinate) {
                        NavigationLink(destination: ParkingLotDetailView(parkingLot: lot)) {
                            Image(systemName: "car.fill")
                                .foregroundColor(lotColor(for: lot))
                                .background(Circle().fill(.white))
                                .padding(5)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Find your parking spot")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.top)
                    
                    Spacer()
                    
                    HStack {
                        // Legend
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Circle().fill(.blue).frame(width: 10, height: 10); Text("Available electric car spots") }
                            HStack { Circle().fill(.green).frame(width: 10, height: 10); Text("Available spots") }
                            HStack { Circle().fill(.red).frame(width: 10, height: 10); Text("Full") }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        // EV Toggle
                        Toggle("Electric car spots", isOn: $showEVOnly)
                            .onChange(of: showEVOnly) { newValue in
                                DispatchQueue.main.async {
                                    if newValue {
                                        incrementWeekdayCounter()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .frame(width: 150)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: fetchParkingLots)
        }
        .navigationBarHidden(true)
    }

    func incrementWeekdayCounter() {
        // Get the current day of the week in English and capitalize it
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US") // Ensure English locale
        dateFormatter.dateFormat = "EEEE" // Full weekday name
        
        let weekday = dateFormatter.string(from: Date()) // Capitalized weekday name

        // Define the URL to fetch the document
        guard let fetchUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SzkDDfUxEKfSFVblmq9O") else {
            print("Invalid URL for Firebase fetch")
            return
        }
        
        // Fetch the current value
        URLSession.shared.dataTask(with: fetchUrl) { data, response, error in
            if let error = error {
                print("Error fetching current counter: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let fields = json["fields"] as? [String: Any],
                   let weekdayField = fields[weekday] as? [String: Any],
                   let currentValueString = weekdayField["integerValue"] as? String,
                   let currentValue = Int(currentValueString) {
                    
                    // Increment the current value by 1
                    let updatedValue = currentValue + 1
                    
                    // Define the URL with document path for updating
                    guard let updateUrl = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/data/SzkDDfUxEKfSFVblmq9O?updateMask.fieldPaths=\(weekday)") else {
                        print("Invalid URL for Firebase update")
                        return
                    }

                    // Define the request payload with updated value
                    let payload: [String: Any] = [
                        "fields": [
                            weekday: ["integerValue": "\(updatedValue)"]
                        ]
                    ]
                    
                    // Serialize payload to JSON
                    guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                        print("Error encoding JSON")
                        return
                    }
                    
                    // Configure the request
                    var request = URLRequest(url: updateUrl)
                    request.httpMethod = "PATCH"
                    request.httpBody = jsonData
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    // Perform the update request
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("Error updating weekday counter: \(error.localizedDescription)")
                        } else {
                            print("Weekday counter updated successfully for \(weekday) with new value: \(updatedValue)")
                        }
                    }.resume()
                    
                } else {
                    print("Error parsing current counter value")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    func lotColor(for lot: ParkingLot) -> Color {
        if lot.availableEVSpots > 0 {
            return .blue
        } else if lot.availableSpots > 0 {
            return .green
        } else {
            return .red
        }
    }

    func fetchParkingLots() {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching parking lots: \(error.localizedDescription)")
                // If the fetch fails, use cached data if available
                DispatchQueue.main.async {
                    self.parkingLots = cachedParkingLots // Use cached data
                }
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let documents = json["documents"] as? [[String: Any]] {
                    let newParkingLots = documents.compactMap { document -> ParkingLot? in
                        guard let fields = document["fields"] as? [String: Any],
                              let name = fields["name"] as? [String: String],
                              let latitude = fields["latitude"] as? [String: Double],
                              let longitude = fields["longitude"] as? [String: Double],
                              let availableSpots = fields["availableSpots"] as? [String: String],
                              let availableEVSpots = fields["available_ev_spots"] as? [String: String],
                              let farePerDay = fields["farePerDay"] as? [String: String],
                              let openTime = fields["open_time"] as? [String: String],
                              let closeTime = fields["close_time"] as? [String: String] else {
                            return nil
                        }

                        return ParkingLot(
                            id: document["name"] as? String ?? UUID().uuidString,
                            name: name["stringValue"] ?? "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: latitude["doubleValue"] ?? 0,
                                longitude: longitude["doubleValue"] ?? 0
                            ),
                            availableSpots: Int(availableSpots["integerValue"] ?? "") ?? 0,
                            availableEVSpots: Int(availableEVSpots["integerValue"] ?? "") ?? 0,
                            farePerDay: Int(farePerDay["integerValue"] ?? "") ?? 0,
                            openTime: openTime["stringValue"] ?? "N/A",
                            closeTime: closeTime["stringValue"] ?? "N/A"
                        )
                    }

                    DispatchQueue.main.async {
                        self.cachedParkingLots = newParkingLots // Cache the fetched data
                        self.parkingLots = newParkingLots // Update the main data
                    }
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
}
