import SwiftUI

struct SignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var dateOfBirth: String = ""
    @State private var uniandesCode: String = ""
    
    var body: some View {
        ZStack {
            backgroundView()
            
            ScrollView {
                
                VStack {
                    Spacer()
                    
                    logoView()
                    
                    formFields()
                    
                    termsOfServiceView()
                    
                    registerButton()
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    // Background color view
    func backgroundView() -> some View {
        Color(red: 246/255, green: 74/255, blue: 85/255)
            .ignoresSafeArea()
    }
    
    // Logo and app name
    func logoView() -> some View {
        VStack {
            Image(systemName: "car.fill") // TODO
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("SeneParking")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text("Register")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            Text("Please enter your information to create an account")
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 20)
        }
    }
    
    // Form fields for user input
    func formFields() -> some View {
        VStack {
            TextField("First name", text: $firstName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 10)
            
            TextField("Last name", text: $lastName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 10)
            
            TextField("Email", text: $email)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 10)
            
            TextField("Mobile number", text: $mobileNumber)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 10)
            
            TextField("Date of birth", text: $dateOfBirth)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 10)
            
            TextField("Uniandes code", text: $uniandesCode)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.bottom, 20)
        }
    }
    
    // Terms of Service Text
    func termsOfServiceView() -> some View {
        Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
            .font(.footnote)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.bottom, 30)
    }
    
    // Register button
    func registerButton() -> some View {
        Button(action: {
            // Add registration action here
        }) {
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
            .padding(.trailing, 10)
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
