import SwiftUI

struct CreditCardForm: View {
    @Binding var cardNumber: String
    @Binding var cardHolderName: String
    @Binding var expiryDate: String
    @Binding var cvv: String
    @Binding var shouldSaveCard: Bool
    @Binding var isSavedCardSelected: Bool
    @State var selectedSavedCard: SavedCard?
    
    // Error states
    @State private var cardNumberError: String?
    @State private var cardHolderError: String?
    @State private var expiryError: String?
    @State private var cvvError: String?
    
    private let savedCards: [SavedCard] = PaymentDataManager.shared.getSavedCards()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Card Details")
                .font(.headline)
            
            if !savedCards.isEmpty {
                savedCardsSection
            }
            
            if selectedSavedCard == nil {
                newCardForm
            } else {
                savedCardForm
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
            
            ForEach(savedCards) { card in
                Button(action: { selectSavedCard(card) }) {
                    HStack {
                        Image(systemName: selectedSavedCard?.id == card.id ? "checkmark.circle.fill" : "circle")
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
            
            Button(action: {
                selectedSavedCard = nil
                clearForm()
            }) {
                Text("Use a different card")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Divider()
                .padding(.vertical)
        }
    }
    
    private var savedCardForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Card ending in \(selectedSavedCard?.lastFourDigits ?? "")")
                Spacer()
                Text(selectedSavedCard?.cardHolderName ?? "")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                SecureField("CVV", text: $cvv)
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
    
    private var newCardForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Card Number
            VStack(alignment: .leading) {
                TextField("Card Number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: cardNumber) { _ in
                        formatCardNumber()
                        validateCardNumber()
                    }
                
                if let error = cardNumberError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Cardholder Name
            VStack(alignment: .leading) {
                TextField("Cardholder Name", text: $cardHolderName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: cardHolderName) { newValue in
                        let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                        cardHolderName = filtered.prefix(30).description
                        validateCardHolder()
                    }
                    .textInputAutocapitalization(.words)
                
                if let error = cardHolderError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                // Expiry Date
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
                
                // CVV
                VStack(alignment: .leading) {
                    SecureField("CVV", text: $cvv)
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
            
            if !cardNumber.isEmpty && !cardHolderName.isEmpty {
                Toggle("Save card for future payments", isOn: $shouldSaveCard)
                    .font(.footnote)
                    .padding(.top, 10)
            }
        }
    }
    
    private func clearForm() {
       cardNumber = ""
       cardHolderName = ""
       expiryDate = ""
       cvv = ""
       shouldSaveCard = false
       cardNumberError = nil
       cardHolderError = nil
       expiryError = nil
       cvvError = nil
       isSavedCardSelected = false  // Update when form is cleared
   }
    
    private func selectSavedCard(_ card: SavedCard) {
        selectedSavedCard = card
        cardNumber = "•••• •••• •••• " + card.lastFourDigits
        cardHolderName = card.cardHolderName
        expiryDate = ""
        cvv = ""
        shouldSaveCard = false
        isSavedCardSelected = true  // Update when card is selected
    }
    
    private func formatCardNumber() {
        var cleaned = cardNumber.filter { $0.isNumber }
        cleaned = String(cleaned.prefix(16))
        
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
