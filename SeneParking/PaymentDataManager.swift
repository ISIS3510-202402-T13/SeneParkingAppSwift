//
//  PaymentDataManager.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 27/11/24.
//

import Foundation

struct PaymentHistory: Codable {
    let parkingLotName: String
    let amount: Double
    let date: Date
    let lastFourDigits: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SavedCard: Identifiable, Codable {
    let id: UUID
    let lastFourDigits: String
    let cardHolderName: String
    let isDefault: Bool
    
    init(lastFourDigits: String, cardHolderName: String, isDefault: Bool) {
        self.id = UUID()
        self.lastFourDigits = lastFourDigits
        self.cardHolderName = cardHolderName
        self.isDefault = isDefault
    }
}

class PaymentDataManager {
    static let shared = PaymentDataManager()
    private let userDefaults = UserDefaults.standard
    
    private let paymentHistoryKey = "paymentHistory"
    private let savedCardsKey = "savedCards"
    
    // Save a new payment to history
    func savePaymentToHistory(parkingLot: String, amount: Double, lastFourDigits: String) {
        var history = getPaymentHistory()
        let payment = PaymentHistory(
            parkingLotName: parkingLot,
            amount: amount,
            date: Date(),
            lastFourDigits: lastFourDigits
        )
        history.insert(payment, at: 0)
        
        // Keep only last 10 payments
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: paymentHistoryKey)
        }
    }
    
    // Get payment history
    func getPaymentHistory() -> [PaymentHistory] {
        guard let data = userDefaults.data(forKey: paymentHistoryKey),
              let history = try? JSONDecoder().decode([PaymentHistory].self, from: data) else {
            return []
        }
        return history
    }
    
    // Save card details (only last 4 digits and cardholder name)
    func saveCard(lastFourDigits: String, cardHolderName: String, makeDefault: Bool = false) {
        var savedCards = getSavedCards()
        
        // If making this card default, remove default status from others
        if makeDefault {
            savedCards = savedCards.map { card in
                SavedCard(lastFourDigits: card.lastFourDigits,
                         cardHolderName: card.cardHolderName,
                         isDefault: false)
            }
        }
        
        // Add new card
        let newCard = SavedCard(
            lastFourDigits: lastFourDigits,
            cardHolderName: cardHolderName,
            isDefault: makeDefault
        )
        
        // Remove existing card with same last 4 digits if exists
        savedCards.removeAll { $0.lastFourDigits == lastFourDigits }
        savedCards.insert(newCard, at: 0)
        
        // Keep only last 5 cards
        if savedCards.count > 5 {
            savedCards = Array(savedCards.prefix(5))
        }
        
        if let encoded = try? JSONEncoder().encode(savedCards) {
            userDefaults.set(encoded, forKey: savedCardsKey)
        }
    }
    
    // Get saved cards
    func getSavedCards() -> [SavedCard] {
        guard let data = userDefaults.data(forKey: savedCardsKey),
              let cards = try? JSONDecoder().decode([SavedCard].self, from: data) else {
            return []
        }
        return cards
    }
    
    // Clear all saved data
    func clearAllData() {
        userDefaults.removeObject(forKey: paymentHistoryKey)
        userDefaults.removeObject(forKey: savedCardsKey)
    }
}
