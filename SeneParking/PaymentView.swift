//
//  PaymentView.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 27/11/24.
//

import SwiftUI

struct PaymentView: View {
    let parkingLot: ParkingLot
    let reservationDuration: TimeInterval
    @State private var selectedPaymentMethod = PaymentMethod.creditCard
    @State private var isProcessing = false
    @State private var showingConfirmation = false
    @State private var paymentError: String? = nil
    @State private var shouldSaveCard = false  // Add this line
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToMainMap = false
    
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
        // Calculate based on parking lot fare and duration
        let hours = ceil(reservationDuration / 3600) // Convert seconds to hours, rounding up
        return Double(parkingLot.farePerDay) * (hours / 24.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Payment Summary
                    PaymentSummaryCard(
                        parkingLotName: parkingLot.name,
                        duration: reservationDuration,
                        amount: totalAmount
                    )
                    
                    // Payment Method Selection
                    PaymentMethodSelector(
                        selectedMethod: $selectedPaymentMethod
                    )
                    
                    // Credit Card Form
                    if selectedPaymentMethod == .creditCard || selectedPaymentMethod == .debit {
                        CreditCardForm(
                            cardNumber: $cardNumber,
                            cardHolderName: $cardHolderName,
                            expiryDate: $expiryDate,
                            cvv: $cvv
                        )
                    }
                    
                    // Digital Payment Instructions
                    if selectedPaymentMethod == .nequi || selectedPaymentMethod == .daviplata {
                        DigitalPaymentInstructions(
                            paymentMethod: selectedPaymentMethod
                        )
                    }
                    
                    // Error Message
                    if let error = paymentError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Pay Button
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
                        navigateToMainMap = true
                    }
                )
            }
        }
        .navigationDestination(isPresented: $navigateToMainMap) {
            MainMapView()
        }
    }
    
    private func processPayment() {
           isProcessing = true
           paymentError = nil
           
           let workItem = DispatchWorkItem {
               // Simulate success scenario (90% success rate)
               let success = Double.random(in: 0...1) < 0.9
               
               self.isProcessing = false
               
               if success {
                   // Save payment history
                   let lastFour = String(self.cardNumber.filter { $0.isNumber }.suffix(4))
                   PaymentDataManager.shared.savePaymentToHistory(
                       parkingLot: self.parkingLot.name,
                       amount: self.totalAmount,
                       lastFourDigits: lastFour
                   )
                   
                   // Save card if user opted to
                   if self.selectedPaymentMethod == .creditCard && self.shouldSaveCard {
                       PaymentDataManager.shared.saveCard(
                           lastFourDigits: lastFour,
                           cardHolderName: self.cardHolderName,
                           makeDefault: true
                       )
                   }
                   
                   self.showingConfirmation = true
               } else {
                   self.paymentError = "Payment failed. Please try again."
               }
           }
           
           // Schedule the work item to execute after 2 seconds
           DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2, execute: workItem)
       }
   
    
    private func isFormValid() -> Bool {
        switch selectedPaymentMethod {
        case .creditCard, .debit:
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

struct CreditCardForm: View {
    @Binding var cardNumber: String
    @Binding var cardHolderName: String
    @Binding var expiryDate: String
    @Binding var cvv: String
    @State private var selectedSavedCard: SavedCard?
    
    // Error states
    @State private var cardNumberError: String?
    @State private var cardHolderError: String?
    @State private var expiryError: String?
    @State private var cvvError: String?
    
    private let savedCards = PaymentDataManager.shared.getSavedCards()
    @State private var shouldSaveCard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Card Details")
                .font(.headline)
            
            if !savedCards.isEmpty {
                savedCardsSection
            }
            
            customCardForm
            
            if cardNumber.count >= 15 {
                Toggle("Save card for future payments", isOn: $shouldSaveCard)
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var savedCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Cards")
                .font(.subheadline)
            
            ForEach(savedCards, id: \.lastFourDigits) { card in
                Button(action: { selectSavedCard(card) }) {
                    HStack {
                        Image(systemName: selectedSavedCard?.lastFourDigits == card.lastFourDigits
                              ? "checkmark.circle.fill" : "circle")
                        VStack(alignment: .leading) {
                            Text("•••• \(card.lastFourDigits)")
                            Text(card.cardHolderName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if card.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            
            Divider()
                .padding(.vertical)
        }
    }
    
    private var customCardForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading) {
                TextField("Card Number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: cardNumber) { newValue in
                        formatCardNumber()
                        validateCardNumber()
                    }
                
                if let error = cardNumberError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading) {
                TextField("Cardholder Name", text: $cardHolderName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: cardHolderName) { _ in
                        validateCardHolder()
                    }
                
                if let error = cardHolderError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    TextField("MM/YY", text: $expiryDate)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: expiryDate) { _ in
                            formatExpiryDate()
                            validateExpiryDate()
                        }
                    
                    if let error = expiryError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading) {
                    TextField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: cvv) { _ in
                            validateCVV()
                        }
                    
                    if let error = cvvError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func selectSavedCard(_ card: SavedCard) {
        selectedSavedCard = card
        cardHolderName = card.cardHolderName
        cardNumber = "•••• •••• •••• " + card.lastFourDigits
        // Clear other fields as they need to be entered fresh for security
        expiryDate = ""
        cvv = ""
    }
    
    private func formatCardNumber() {
        // Remove any non-digits
        var cleaned = cardNumber.filter { $0.isNumber }
        
        // Limit to 16 digits
        cleaned = String(cleaned.prefix(16))
        
        // Add spaces every 4 digits
        var formatted = ""
        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        cardNumber = formatted
    }
    
    private func validateCardNumber() {
        let digits = cardNumber.filter { $0.isNumber }
        if digits.isEmpty {
            cardNumberError = "Card number is required"
        } else if digits.count < 16 {
            cardNumberError = "Card number must be 16 digits"
        } else {
            cardNumberError = nil
        }
    }
    
    private func validateCardHolder() {
        if cardHolderName.isEmpty {
            cardHolderError = "Cardholder name is required"
        } else if cardHolderName.count < 3 {
            cardHolderError = "Please enter full name"
        } else {
            cardHolderError = nil
        }
    }
    
    private func formatExpiryDate() {
        var cleaned = expiryDate.filter { $0.isNumber }
        cleaned = String(cleaned.prefix(4))
        
        if cleaned.count >= 2 {
            let month = String(cleaned.prefix(2))
            let remaining = String(cleaned.dropFirst(2))
            
            // Validate month
            if let monthNum = Int(month), monthNum >= 1 && monthNum <= 12 {
                expiryDate = "\(month)/\(remaining)"
            } else {
                expiryDate = ""
                expiryError = "Invalid month"
            }
        } else {
            expiryDate = cleaned
        }
    }
    
    private func validateExpiryDate() {
        let components = expiryDate.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]) else {
            expiryError = "Invalid expiry date"
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if year < currentYear || (year == currentYear && month < currentMonth) {
            expiryError = "Card has expired"
        } else {
            expiryError = nil
        }
    }
    
    private func validateCVV() {
        let digits = cvv.filter { $0.isNumber }
        cvv = String(digits.prefix(3))
        
        if digits.isEmpty {
            cvvError = "CVV is required"
        } else if digits.count < 3 {
            cvvError = "CVV must be 3 digits"
        } else {
            cvvError = nil
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
