import SwiftUI

struct SignInView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 246/255, green: 74/255, blue: 85/255) // Custom pink color
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo
                Image(systemName: "car.fill") // TODO
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // App name
                Text("SeneParking")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Text fields for mobile/university ID and password
                TextField("Mobile number or university id", text: $username)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.bottom, 15)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                
                // Login button
                Button(action: {
                    // TODO Add login action here
                }) {
                    Text("Log in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.bottom, 10)
                
                // Forgotten password text
                Button(action: {
                    // TODO Add forgotten password action here
                }) {
                    Text("Forgotten password?")
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
                
                // Create new account button
                Button(action: {
                    // TODO Add create new account action here
                }) {
                    Text("Create new account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
