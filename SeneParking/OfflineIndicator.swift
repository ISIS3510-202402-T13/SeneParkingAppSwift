//
//  OfflineIndicator.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 24/11/24.
//

import SwiftUI

struct OfflineIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.white)
            
            Text("Offline")
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.8))
        .cornerRadius(20)
        .shadow(radius: 2)
    }
}
