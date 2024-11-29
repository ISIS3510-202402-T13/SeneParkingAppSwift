//
//  TimeSelectionView.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 23/11/24.
//

import SwiftUI

struct TimeSelectionView: View {
    @Binding var selectedStartTime: Date
    @Binding var selectedDuration: Int // Duration in hours
    @State private var showCustomTime = false
    @State private var customEndTime = Date()
    
    private let availableHours = [1, 2, 3, 4, 6, 8, 12]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Start Time Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting Time")
                    .font(.headline)
                
                DatePicker("", selection: $selectedStartTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }
            
            // Duration Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.headline)
                
                HStack {
                    Button(action: { showCustomTime.toggle() }) {
                        HStack {
                            Image(systemName: showCustomTime ? "checkmark.circle.fill" : "circle")
                            Text("Custom End Time")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                if showCustomTime {
                    DatePicker("End Time", selection: $customEndTime, in: selectedStartTime..., displayedComponents: [.hourAndMinute])
                        .onChange(of: customEndTime) { newValue in
                            let hours = Calendar.current.dateComponents([.hour], from: selectedStartTime, to: newValue).hour ?? 0
                            selectedDuration = max(1, hours)
                        }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableHours, id: \.self) { hours in
                                Button(action: {
                                    selectedDuration = hours
                                }) {
                                    Text("\(hours)h")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedDuration == hours ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedDuration == hours ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            
            // Summary
            if let endTime = Calendar.current.date(byAdding: .hour, value: selectedDuration, to: selectedStartTime) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.headline)
                    
                    Text("From: \(formatDate(selectedStartTime))")
                    Text("To: \(formatDate(endTime))")
                    Text("Duration: \(selectedDuration) hours")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
