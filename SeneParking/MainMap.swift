import SwiftUI
import MapKit

struct MainMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6015, longitude: -74.0655), // Coordinates for Universidad de los Andes
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showEVOnly = false
    @State private var parkingLots: [ParkingLot] = []
    
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
                                .foregroundColor(lot.availableEVSpots > 0 ? .green : .red)
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
                        Toggle("Show EV Only", isOn: $showEVOnly)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadParkingLots)
        }
        .navigationBarHidden(true)
    }
    
    func loadParkingLots() {
        // In a real app, this would fetch data from your backend
        parkingLots = [
            ParkingLot(id: 1, name: "SantoDomingo building", coordinate: CLLocationCoordinate2D(latitude: 4.6020, longitude: -74.0660), availableSpots: 10, availableEVSpots: 2, price: "$5/hour", openingTime: "6:00 AM", closingTime: "10:00 PM"),
            ParkingLot(id: 2, name: "Lot B", coordinate: CLLocationCoordinate2D(latitude: 4.6010, longitude: -74.0650), availableSpots: 5, availableEVSpots: 0, price: "$4/hour", openingTime: "7:00 AM", closingTime: "9:00 PM")
        ]
    }
}

struct ParkingLot: Identifiable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    let availableSpots: Int
    let availableEVSpots: Int
    let price: String
    let openingTime: String
    let closingTime: String
}

struct MainMap_Previews: PreviewProvider {
    static var previews: some View {
        MainMapView()
    }
}
