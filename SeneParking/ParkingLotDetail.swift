//
//  ParkingLotDetail.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 2/10/24.
//

import SwiftUI
import MapKit

struct ParkingLotDetail: View {
    let parkingLot: ParkingLot
    
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
                    // Action to navigate to the parking lot
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
                
                InfoRow(title: "Available Spots", value: "\(parkingLot.availableSpots)")
                InfoRow(title: "Available EV Spots", value: "\(parkingLot.availableEVSpots)")
                InfoRow(title: "Price", value: parkingLot.price)
                InfoRow(title: "Opening Hours", value: "\(parkingLot.openingTime) - \(parkingLot.closingTime)")
            }
            .padding()
        }
        .navigationTitle("Parking Lot Details")
        .navigationBarTitleDisplayMode(.inline)
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

struct ParkingLotDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ParkingLotDetail(parkingLot: ParkingLot(id: 1, name: "Lot A", coordinate: CLLocationCoordinate2D(latitude: 4.6020, longitude: -74.0660), hasEVSpots: true, availableSpots: 10, availableEVSpots: 2, price: "$5/hour", openingTime: "6:00 AM", closingTime: "10:00 PM"))
        }
    }
}
