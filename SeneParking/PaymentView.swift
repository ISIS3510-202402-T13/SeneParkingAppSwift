import SwiftUI

struct PaymentView: View {
    let parkingLot: ParkingLot
    let reservationDuration: TimeInterval
    @State private var selectedPaymentMethod = PaymentMethod.creditCard
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    @State private var paymentError: String? = nil
    @State private var shouldSaveCard = false
    @State private var navigateToReservations = false
    @State private var isSavedCardSelected = false
    @Environment(\.presentationMode) var presentationMode
    
    // Credit card form states
    @State private var cardNumber = ""
    @State private var cardHolderName = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    
    enum PaymentMethod: String, CaseIterable {
        case creditCard = "Credit Card"
        case debit = "Debit Card"
        case nequi = "Nequi"
        case daviplata = "Daviplata"
    }
    
    private var totalAmount: Double {
        let hours = ceil(reservationDuration / 3600)
        return Double(parkingLot.farePerDay) * (hours / 24.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PaymentSummaryCard(
                        parkingLotName: parkingLot.name,
                        duration: reservationDuration,
                        amount: totalAmount
                    )
                    
                    PaymentMethodSelector(
                        selectedMethod: $selectedPaymentMethod
                    )
                    
                    if selectedPaymentMethod == .creditCard || selectedPaymentMethod == .debit {
                        CreditCardForm(
                            cardNumber: $cardNumber,
                            cardHolderName: $cardHolderName,
                            expiryDate: $expiryDate,
                            cvv: $cvv,
                            shouldSaveCard: $shouldSaveCard,
                            isSavedCardSelected: $isSavedCardSelected
                        )
                    }
                    
                    if selectedPaymentMethod == .nequi || selectedPaymentMethod == .daviplata {
                        DigitalPaymentInstructions(
                            paymentMethod: selectedPaymentMethod
                        )
                    }
                    
                    if let error = paymentError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    Button(action: processPayment) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isProcessing ? "Processing..." : "Pay \(formatPrice(totalAmount))")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing || !isFormValid())
                    
                    Divider()
                        .padding(.vertical)
                    
                    PaymentHistorySection()
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Payment Successful"),
                    message: Text("Your parking spot has been reserved."),
                    dismissButton: .default(Text("OK")) {
                        navigateToReservations = true
                    }
                )
            }
        }
        .navigationDestination(isPresented: $navigateToReservations) {
            MyReservationsView()
        }
    }
    
    private func processPayment() {
        isProcessing = true
        paymentError = nil

        let workItem = DispatchWorkItem {
            let success = Double.random(in: 0...1) < 0.3
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if success {
                    let lastFour = String(self.cardNumber.filter { $0.isNumber }.suffix(4))
                    PaymentDataManager.shared.savePaymentToHistory(
                        parkingLot: self.parkingLot.name,
                        amount: self.totalAmount,
                        lastFourDigits: lastFour
                    )

                    if self.shouldSaveCard {
                        PaymentDataManager.shared.saveCard(
                            lastFourDigits: lastFour,
                            cardHolderName: self.cardHolderName,
                            makeDefault: true
                        )
                    }
                    
                    self.createReservationRecord(
                        parkingLotId: self.parkingLot.id,
                        parkingLotName: self.parkingLot.name,
                        startTime: Date(),
                        duration: self.reservationDuration,
                        fareAmount: self.totalAmount
                    )
                    
                    self.showingConfirmation = true
                } else {
                    self.paymentError = "Payment failed. Please try again."
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2, execute: workItem)
    }

    private func createReservationRecord(parkingLotId: String, parkingLotName: String, startTime: Date, duration: TimeInterval, fareAmount: Double) {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/seneparking-f457b/databases/(default)/documents/reservations") else {
            return
        }
        
        let endTime = startTime.addingTimeInterval(duration)
        let dateFormatter = ISO8601DateFormatter()

        let reservationData: [String: Any] = [
            "fields": [
                "parkingLotId": ["stringValue": parkingLotId],
                "parkingLotName": ["stringValue": parkingLotName],
                "startTime": ["timestampValue": dateFormatter.string(from: startTime)],
                "endTime": ["timestampValue": dateFormatter.string(from: endTime)],
                "status": ["stringValue": "upcoming"],
                "fareAmount": ["doubleValue": fareAmount],
                "userId": ["stringValue": "current-user-id"]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: reservationData)
        } catch {
            print("Error encoding reservation data: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating reservation: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("Error creating reservation: HTTP \(httpResponse.statusCode)")
                return
            }
        }.resume()
    }
    
    private func isFormValid() -> Bool {
        switch selectedPaymentMethod {
        case .creditCard, .debit:
            if isSavedCardSelected {
                return cvv.count == 3
            }
            return cardNumber.count >= 16 &&
                   !cardHolderName.isEmpty &&
                   expiryDate.count == 5 &&
                   cvv.count == 3
        case .nequi, .daviplata:
            return true
        }
    }
    
    private func formatPrice(_ amount: Double) -> String {
        return String(format: "COP $%.2f", amount)
    }
}

struct PaymentSummaryCard: View {
    let parkingLotName: String
    let duration: TimeInterval
    let amount: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Summary")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                PaymentInfoRow(label: "Parking Lot", value: parkingLotName)
                PaymentInfoRow(label: "Duration", value: formatDuration(duration))
                PaymentInfoRow(label: "Amount", value: String(format: "COP $%.2f", amount))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(ceil(timeInterval / 3600))
        return "\(hours) \(hours == 1 ? "hour" : "hours")"
    }
}

struct PaymentMethodSelector: View {
    @Binding var selectedMethod: PaymentView.PaymentMethod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Method")
                .font(.headline)
            
            ForEach(PaymentView.PaymentMethod.allCases, id: \.self) { method in
                Button(action: { selectedMethod = method }) {
                    HStack {
                        Image(systemName: selectedMethod == method ? "largecircle.fill.circle" : "circle")
                        Text(method.rawValue)
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PaymentInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct PaymentHistorySection: View {
    private let payments = PaymentDataManager.shared.getPaymentHistory()
    
    var body: some View {
        if !payments.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Text("Payment History")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(payments, id: \.date) { payment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(payment.parkingLotName)
                                .fontWeight(.medium)
                            Text(payment.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(String(format: "COP $%.2f", payment.amount))
                                .fontWeight(.semibold)
                            Text("•••• \(payment.lastFourDigits)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

struct DigitalPaymentInstructions: View {
    let paymentMethod: PaymentView.PaymentMethod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Instructions")
                .font(.headline)
            
            Text("1. Open your \(paymentMethod.rawValue) app")
            Text("2. Select 'Pay'")
            Text("3. Enter the business code: SENEPARKING")
            Text("4. Enter the exact amount shown above")
            Text("5. Confirm your payment")
            
            Text("Your reservation will be confirmed automatically once the payment is processed.")
                .padding(.top)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
