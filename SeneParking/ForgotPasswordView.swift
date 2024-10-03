import SwiftUI

struct ForgotPasswordView: View {
    @State private var emailOrPhone: String = ""
    
    var body: some View {
        ZStack {
            Color(red: 246/255, green: 74/255, blue: 85/255)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(systemName: "key.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text("Forgot Password?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                Text("Enter your email or mobile number to reset your password")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                
                TextField("Email or Mobile Number", text: $emailOrPhone)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                
                Button(action: {
                    // Add the action to reset password
                }) {
                    Text("Reset Password")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
