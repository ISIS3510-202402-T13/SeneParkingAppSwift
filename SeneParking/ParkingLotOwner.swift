import SwiftUI

struct ParkingLotOwner: View {
    @State private var parkingLotID: String = ""
    @State private var navigateToManagement = false
    @State private var navigateToRegistration = false
    @State private var errorMessage: String? = nil  // Error message state
    
    @AppStorage("parkingID") private var storedID: String = ""
    
    @Environment(\.dismiss) var dismiss  // Dismiss environment to return to the previous view
    
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
                    
                    if let errorMessage = errorMessage {  // Display error message if not nil
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Navigate to Parking Lot Management
                    NavigationLink(destination: ParkingLotManagementView(parkingLotID: parkingLotID)) {
                        Text("Go to Parking Lot Management")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Navigate to Parking Lot Registration
                    NavigationLink(destination: RegisterParkingLotView()) {
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .padding()
                    }
                }
            }
        }
        .onAppear() {
            if !storedID.isEmpty {
                parkingLotID = storedID
            }
        }
    }
    
    // Function to validate the Parking Lot ID
    private func validateParkingLotID() {
        guard !parkingLotID.isEmpty else {
            errorMessage = "Please enter a valid Parking Lot ID."
            return
        }
        
        let urlString = "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/parkingLots/\(parkingLotID)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL format."
            return
        }
        
        // Perform the fetch request
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    errorMessage = "Parking Lot ID not found. Please try again."
                    return
                }
                
                // Success: Proceed to navigation
                errorMessage = nil
                storedID = parkingLotID  // Save the valid ID
                navigateToManagement = true
            }
        }.resume()
    }
}

struct ParkingLotOwner_Previews: PreviewProvider {
    static var previews: some View {
        ParkingLotOwner()
    }
}
