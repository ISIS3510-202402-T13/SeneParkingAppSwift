import SwiftUI

struct SignInView: View {
    @State private var mobileNumber: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationStack { // Wrap in NavigationStack
            ZStack {
                Color(red: 246/255, green: 74/255, blue: 85/255)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Image(systemName: "car.fill") // Replace with your logo
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Text("SeneParking")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    TextField("Mobile number or university ID", text: $mobileNumber)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                    
                    Button(action: {
                        // Perform login action
                    }) {
                        Text("Log in")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 10)
                    
                    Text("Forgotten password?")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    // NavigationLink to RegisterView
                    NavigationLink(destination: SignUpView()) {
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
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}