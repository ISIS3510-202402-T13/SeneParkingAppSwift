import SwiftUI

struct ParkingLotOwner: View {
    @State private var parkingLotID: String = ""
    @State private var navigateToManagement = false
    @State private var navigateToRegistration = false
    
    @AppStorage("parkingID") private var storedID: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Parking Lot Owner")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    // Parking Lot ID Field
                    TextField("Enter Parking Lot ID", text: $parkingLotID)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                    
                    // Navigate to Parking Lot Management
                    Button(action: {
                        navigateToManagement = true
                        storedID = parkingLotID
                    }) {
                        Text("Go to Parking Lot Management")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Navigate to Parking Lot Registration
                    Button(action: {
                        navigateToRegistration = true
                    }) {
                        Text("Register Parking Lot")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToManagement) {
                ParkingLotManagementView(parkingLotID: parkingLotID)
            }
            .navigationDestination(isPresented: $navigateToRegistration) {
                RegisterParkingLotView()
            }
            .navigationBarHidden(true)
        }
        .onAppear() {
            if !storedID.isEmpty {
                parkingLotID = storedID
            }
        }
    }
}

struct ParkingLotOwner_Previews: PreviewProvider {
    static var previews: some View {
        ParkingLotOwner()
    }
}
