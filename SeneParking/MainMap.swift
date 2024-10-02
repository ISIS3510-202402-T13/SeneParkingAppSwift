//
//  MainMap.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 2/10/24.
//

import SwiftUI
import MapKit

struct MainMap: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6015, longitude: -74.0655), // Coordinates for Universidad de los Andes
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showEVOnly = false
    @State private var parkingLots: [ParkingLot] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: parkingLots) { lot in
                    MapAnnotation(coordinate: lot.coordinate) {
                        NavigationLink(destination: ParkingLotDetail(parkingLot: lot)) {
                            Image(systemName: "car.fill")
                                .foregroundColor(lot.hasEVSpots ? .green : .red)
                                .background(Circle().fill(.white))
                                .padding(5)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    HStack {
                        Toggle("Show EV Only", isOn: $showEVOnly)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("SeneParking")
            .onAppear(perform: loadParkingLots)
        }
    }
    
    func loadParkingLots() {
        // In a real app, this would fetch data from your backend
        parkingLots = [
            ParkingLot(id: 1, name: "Lot A", coordinate: CLLocationCoordinate2D(latitude: 4.6020, longitude: -74.0660), hasEVSpots: true, availableSpots: 10, availableEVSpots: 2, price: "$5/hour", openingTime: "6:00 AM", closingTime: "10:00 PM"),
            ParkingLot(id: 2, name: "Lot B", coordinate: CLLocationCoordinate2D(latitude: 4.6010, longitude: -74.0650), hasEVSpots: false, availableSpots: 5, availableEVSpots: 0, price: "$4/hour", openingTime: "7:00 AM", closingTime: "9:00 PM")
        ]
    }
}

struct ParkingLot: Identifiable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    let hasEVSpots: Bool
    let availableSpots: Int
    let availableEVSpots: Int
    let price: String
    let openingTime: String
    let closingTime: String
}

struct MainMapView_Previews: PreviewProvider {
    static var previews: some View {
        MainMap()
    }
}
